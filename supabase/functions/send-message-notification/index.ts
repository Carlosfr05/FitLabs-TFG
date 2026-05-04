// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// Interfaz para el cuerpo de la solicitud (el nuevo mensaje)
interface Mensaje {
    id_destinatario: string;
    id_remitente: string;
    id_chat?: string;
    contenido: string;
    tipo_contenido: string;
}

// Algunos payloads del webhook pueden no incluir id_destinatario.
// En ese caso lo resolvemos con los participantes del chat.
async function resolveDestinatario(
    supabaseClient: ReturnType<typeof createClient>,
    mensaje: Mensaje,
): Promise<string> {
    if (mensaje.id_destinatario && mensaje.id_destinatario.trim().length > 0) {
        return mensaje.id_destinatario;
    }

    if (!mensaje.id_chat) {
        throw new Error("El payload no incluye id_destinatario ni id_chat para resolver destinatario.");
    }

    const { data: chat, error: chatError } = await supabaseClient
        .from("chats")
        .select("id_usuario1, id_usuario2")
        .eq("id", mensaje.id_chat)
        .single();

    if (chatError || !chat) {
        throw new Error(`No se pudo cargar el chat ${mensaje.id_chat}. Error: ${chatError?.message}`);
    }

    if (chat.id_usuario1 === mensaje.id_remitente) return chat.id_usuario2;
    if (chat.id_usuario2 === mensaje.id_remitente) return chat.id_usuario1;

    throw new Error(
        `El remitente ${mensaje.id_remitente} no coincide con participantes del chat ${mensaje.id_chat}`,
    );
}

// Nota: para simplificar el despliegue, la función enviará notificaciones
// usando la clave de servidor FCM (legacy) si está disponible en
// el secret `FIREBASE_SERVER_KEY`. Si prefieres usar la API v1 con
// OAuth2, necesitaríamos firmar un JWT con la cuenta de servicio.
// Para evitar dependencias adicionales en el bundler, recomendamos
// añadir el secret `FIREBASE_SERVER_KEY` en Supabase.

// Función para acortar el contenido del mensaje
function previewMessage(tipo: string, contenido: string): string {
    switch (tipo) {
        case "imagen":
            return "Te ha enviado una foto";
        case "video":
            return "Te ha enviado un video";
        case "audio":
            return "Te ha enviado un audio";
        default:
            const text = (contenido || "").trim();
            return text.length === 0 ? "Tienes un mensaje nuevo" : text;
    }
}

serve(async (req) => {
    // Manejo de la solicitud pre-vuelo (CORS)
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { record: mensaje } = (await req.json()) as { record: Mensaje };

        console.log("📩 Función disparada con mensaje:", {
            id_destinatario: mensaje.id_destinatario,
            id_remitente: mensaje.id_remitente,
            id_chat: mensaje.id_chat,
            tipo_contenido: mensaje.tipo_contenido,
        });

        // Crear un cliente de Supabase con Service Role para saltar RLS en la función.
        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
        const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

        if (!supabaseUrl || !serviceRoleKey) {
            throw new Error("Faltan SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en los secretos de la función.");
        }

        const supabaseClient = createClient(supabaseUrl, serviceRoleKey);

        // 1. Resolver y obtener el token FCM del destinatario
        const destinatarioId = await resolveDestinatario(supabaseClient, mensaje);
        console.log("🔍 Buscando token FCM para:", destinatarioId);
        const { data: perfilDestinatario, error: errorDestinatario } = await supabaseClient
            .from("perfiles")
            .select("fcm_token")
            .eq("id", destinatarioId)
            .single();

        console.log("📱 Resultado de búsqueda:", {
            error: errorDestinatario?.message,
            fcm_token: perfilDestinatario?.fcm_token ? "✅ Encontrado" : "❌ No encontrado",
        });

        if (errorDestinatario || !perfilDestinatario?.fcm_token) {
            throw new Error(
                `No se pudo encontrar el perfil o el token FCM para el destinatario: ${destinatarioId}. Error: ${errorDestinatario?.message}`
            );
        }

        const fcmToken = perfilDestinatario.fcm_token;

        // 2. Obtener el nombre del remitente
        console.log("👤 Buscando perfil del remitente:", mensaje.id_remitente);
        const { data: perfilRemitente, error: errorRemitente } = await supabaseClient
            .from("perfiles")
            .select("nombre, username")
            .eq("id", mensaje.id_remitente)
            .single();

        if (errorRemitente) {
            throw new Error(`No se pudo encontrar el perfil del remitente: ${mensaje.id_remitente}. Error: ${errorRemitente.message}`);
        }

        const senderName = perfilRemitente.nombre ?? perfilRemitente.username ?? "Alguien";
        const body = previewMessage(mensaje.tipo_contenido, mensaje.contenido);

        console.log("✉️ Notificación a enviar:", {
            fcmToken: fcmToken.substring(0, 20) + "...",
            title: senderName,
            body: body,
        });

        // 3. Construir y enviar la notificación de Firebase
        // Preferimos usar la clave de servidor legacy FCM si está disponible
        const serverKey = Deno.env.get("FIREBASE_SERVER_KEY");
        console.log("🔐 Método de autenticación:", serverKey ? "Legacy Server Key" : "Service Account (API v1)");

        if (serverKey) {
            const legacyPayload = {
                to: fcmToken,
                notification: {
                    title: senderName,
                    body: body,
                },
                data: {
                    chatId: mensaje.id_chat ?? "",
                    senderId: mensaje.id_remitente,
                },
            };

            const response = await fetch("https://fcm.googleapis.com/fcm/send", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `key=${serverKey}`,
                },
                body: JSON.stringify(legacyPayload),
            });

            console.log("📤 Respuesta de Firebase (legacy):", response.status);

            if (!response.ok) {
                const errorBody = await response.text();
                console.error("❌ Error en Firebase:", errorBody);
                throw new Error(`Error al enviar la notificación a Firebase (legacy): ${response.status} ${errorBody}`);
            }
            console.log("✅ Notificación enviada exitosamente (legacy)");
        } else if (Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY")) {
            // Usar la API v1 con cuenta de servicio JSON
            console.log("🔑 Obteniendo token de acceso OAuth2...");
            const accessToken = await getAccessToken();
            const projectId = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY")!).project_id;
            const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

            console.log("🎯 URL de Firebase v1:", fcmUrl);

            const notificationPayload = {
                message: {
                    token: fcmToken,
                    notification: {
                        title: senderName,
                        body: body,
                    },
                    data: {
                        chatId: mensaje.id_chat ?? "",
                        senderId: mensaje.id_remitente,
                    },
                },
            };

            const response = await fetch(fcmUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${accessToken}`,
                },
                body: JSON.stringify(notificationPayload),
            });

            console.log("📤 Respuesta de Firebase (v1):", response.status);

            if (!response.ok) {
                const errorBody = await response.text();
                console.error("❌ Error en Firebase v1:", errorBody);
                throw new Error(`Error al enviar la notificación a Firebase (v1): ${response.status} ${errorBody}`);
            }
            console.log("✅ Notificación enviada exitosamente (v1)");
        } else {
            console.error("❌ Sin credenciales de Firebase configuradas");
            throw new Error("Ni FIREBASE_SERVER_KEY ni FIREBASE_SERVICE_ACCOUNT_KEY configuradas. Añade un secret en Supabase con la credencial deseada.");
        }

        console.log("✅ Función completada exitosamente");
        return new Response(JSON.stringify({ success: true }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200,
        });

    } catch (error) {
        console.error("🚨 Error en la función:", error.message);
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 400,
        });
    }
});

// --- Helpers: obtener token OAuth2 desde JSON de cuenta de servicio ---
async function getAccessToken(): Promise<string> {
    const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
    if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY no configurado");
    let svc: any;
    try {
        svc = JSON.parse(raw);
    } catch (parseError) {
        const hint = raw.trim().startsWith("$(")
            ? "Parece que el secreto contiene un comando de PowerShell literal (por ejemplo $(Get-Content ...)). Debes guardar el contenido JSON real de la cuenta de servicio, no el comando."
            : "El secreto no tiene formato JSON válido. Debe ser el JSON completo de la cuenta de servicio de Firebase.";
        throw new Error(`${hint} Detalle: ${(parseError as Error).message}`);
    }

    const iat = Math.floor(Date.now() / 1000);
    const exp = iat + 3600;

    const header = { alg: "RS256", typ: "JWT" };
    const payload = {
        iss: svc.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp,
        iat,
    };

    function base64url(input: string | Uint8Array) {
        let str: string;
        if (input instanceof Uint8Array) {
            str = new TextDecoder().decode(input);
        } else {
            str = input;
        }
        // Convert string -> Uint8Array, then to base64
        const bytes = new TextEncoder().encode(str);
        const b64 = btoa(String.fromCharCode(...bytes));
        return b64.replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    }

    const header64 = base64url(JSON.stringify(header));
    const payload64 = base64url(JSON.stringify(payload));
    const signingInput = `${header64}.${payload64}`;

    // Parse PEM private key (PKCS#8)
    const pem = svc.private_key as string;
    const pemBody = pem.replace(/-----BEGIN PRIVATE KEY-----/, "").replace(/-----END PRIVATE KEY-----/, "").replace(/\s+/g, "");
    const der = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0));

    // Import key
    const key = await crypto.subtle.importKey(
        "pkcs8",
        der.buffer,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    );

    const signature = new Uint8Array(await crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        key,
        new TextEncoder().encode(signingInput)
    ));

    // base64url encode signature
    const sigB64 = btoa(String.fromCharCode(...signature));
    const sig64Url = sigB64.replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

    const jwt = `${signingInput}.${sig64Url}`;

    // Exchange JWT for access token
    const body = new URLSearchParams();
    body.set("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
    body.set("assertion", jwt);

    const resp = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: body.toString(),
    });

    if (!resp.ok) {
        const txt = await resp.text();
        throw new Error(`Error obteniendo access token: ${resp.status} ${txt}`);
    }

    const data = await resp.json();
    if (!data.access_token) throw new Error("no access_token in OAuth response");
    return data.access_token as string;
}
