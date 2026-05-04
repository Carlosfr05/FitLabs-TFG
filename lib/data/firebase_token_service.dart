import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseTokenService {
  static final _messaging = FirebaseMessaging.instance;

  /// Configura y obtiene el token FCM, guardándolo en Supabase.
  /// Debe llamarse después de que Supabase esté inicializado.
  static Future<void> setupAndSaveToken() async {
    print('🔥 [FirebaseTokenService] Iniciando obtención de token FCM...');

    try {
      // Verificar que Firebase esté inicializado
      print(
        '🔥 [FirebaseTokenService] Verificando inicialización de Firebase...',
      );

      // Pedir permisos (necesario en Android 13+ y iOS)
      print('🔔 [FirebaseTokenService] Pidiendo permisos de notificación...');
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print(
        '🔔 [FirebaseTokenService] Estado de permisos: ${settings.authorizationStatus.name}',
      );

      if (settings.authorizationStatus.name == 'denied') {
        print('❌ [FirebaseTokenService] Permisos DENEGADOS por el usuario');
        return;
      }

      // Obtener el token y guardarlo
      print('🔥 [FirebaseTokenService] Obteniendo token de Firebase...');
      final token = await _messaging.getToken();
      print("========== TOKEN DE FIREBASE ==========");
      if (token != null && token.isNotEmpty) {
        print('✅ Token: ${token.substring(0, 30)}...');
      } else {
        print('❌ NULL - NO OBTENIDO');
      }
      print("========================================");

      if (token != null && token.isNotEmpty) {
        print('✅ Token obtenido correctamente, guardando en Supabase...');
        await _saveTokenToSupabase(token);
      } else {
        print('❌ [FirebaseTokenService] Token es null o vacío');
      }

      // Escuchar cambios en el token y guardarlo si cambia
      print(
        '👂 [FirebaseTokenService] Configurando listener de refrescamiento de token...',
      );
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 [FirebaseTokenService] Token refrescado: $newToken');
        _saveTokenToSupabase(newToken);
      });
    } catch (e) {
      print('❌ [FirebaseTokenService] ERROR en setupAndSaveToken: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String? token) async {
    if (token == null) {
      print('⚠️ [FirebaseTokenService] Token es null, abortando...');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      print(
        '⚠️ [FirebaseTokenService] No hay usuario autenticado, token no se guardará',
      );
      return;
    }

    print('💾 [FirebaseTokenService] Guardando token para usuario: $userId');
    print('   Token: ${token.substring(0, 20)}...');

    try {
      await Supabase.instance.client
          .from('perfiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      print(
        '✅ [FirebaseTokenService] Token guardado en Supabase correctamente.',
      );
    } catch (e) {
      print(
        '❌ [FirebaseTokenService] Error al guardar el token en Supabase: $e',
      );
    }
  }
}
