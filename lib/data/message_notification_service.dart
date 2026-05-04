import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';

/// Gestor de notificaciones push recibidas en segundo plano.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No se puede hacer mucho aquí, solo es un punto de entrada.
  // La lógica principal se ejecuta cuando el usuario abre la app.
  print("Handling a background message: ${message.messageId}");
}

/// Servicio global para mostrar notificaciones locales cuando entran mensajes.
class MessageNotificationService {
  MessageNotificationService._();

  static final MessageNotificationService instance =
      MessageNotificationService._();

  static final _db = Supabase.instance.client;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  String? _activeChatId;
  bool _initialized = false;
  bool _notificationsAvailable = true;

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // La inicialización de notificaciones locales sigue siendo necesaria
    // para mostrar las notificaciones cuando llegan.
    await _initializeLocalNotifications();

    // Solo configurar listeners de Firebase en plataformas móviles
    if (_isMobilePlatform) {
      await _initializeFirebaseMessaging();
    }

    _initialized = true;
  }

  /// Inicializa el plugin de notificaciones locales.
  Future<void> _initializeLocalNotifications() async {
    if (!_isMobilePlatform) {
      _notificationsAvailable = false;
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    try {
      await _notifications.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } on MissingPluginException {
      _notificationsAvailable = false;
    }
  }

  /// Configura los listeners de Firebase Cloud Messaging.
  Future<void> _initializeFirebaseMessaging() async {
    // App en segundo plano o terminada -> el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('El usuario ha abierto la app desde una notificación:');
      // Aquí podrías añadir lógica para navegar a la pantalla de chat correcta.
      // Por ejemplo: _handleNotificationNavigation(message.data);
    });

    // App en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('¡Mensaje recibido en primer plano!');
      final incomingChatId = _extractChatId(message);

      if (_shouldSuppressNotification(incomingChatId)) {
        print(
          '🔕 Notificación suprimida porque el chat activo coincide con el mensaje: $incomingChatId',
        );
        return;
      }

      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && _isMobilePlatform) {
        // Si estamos en primer plano, mostramos la notificación manualmente
        // usando flutter_local_notifications.
        _notifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'fitlabs_messages', // El mismo ID de canal que usabas
              'Mensajes',
              channelDescription: 'Notificaciones de mensajes nuevos',
              icon: android
                  ?.smallIcon, // Usa el icono de la notificación si está disponible
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // App en segundo plano (pero no terminada)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Ya no necesitamos escuchar los cambios de Supabase en el cliente.
  /// Esta lógica se moverá a una Edge Function.
  Future<void> startListening() async {
    // Este método puede quedar vacío o ser eliminado.
    // La inicialización ahora se hace una sola vez en `initialize()`.
  }

  Future<void> stopListening() async {
    // Este método también puede ser eliminado.
  }

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
  }

  String? _extractChatId(RemoteMessage message) {
    final dataChatId = message.data['chatId'] ?? message.data['id_chat'];
    if (dataChatId == null) return null;
    final value = dataChatId.toString().trim();
    return value.isEmpty ? null : value;
  }

  bool _shouldSuppressNotification(String? incomingChatId) {
    if (incomingChatId == null) return false;
    if (_activeChatId == null) return false;
    return _activeChatId == incomingChatId;
  }

  // Los métodos _onIncomingMessage y _previewMessage ya no son necesarios aquí,
  // ya que la notificación se construye en la Edge Function.
  // Puedes eliminarlos.
}
