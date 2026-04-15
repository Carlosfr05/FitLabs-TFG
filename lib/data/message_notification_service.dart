import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';

/// Servicio global para mostrar notificaciones locales cuando entran mensajes.
class MessageNotificationService {
  MessageNotificationService._();

  static final MessageNotificationService instance =
      MessageNotificationService._();

  static final _db = Supabase.instance.client;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  RealtimeChannel? _channel;
  String? _listeningUserId;
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
    if (!_isMobilePlatform) {
      _notificationsAvailable = false;
      _initialized = true;
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

    _initialized = true;
  }

  Future<void> startListening() async {
    await initialize();
    if (!_notificationsAvailable) return;

    final userId = SessionService.userId;
    if (userId == null) return;

    if (_listeningUserId == userId && _channel != null) return;

    await stopListening();
    _listeningUserId = userId;

    _channel = _db
        .channel('incoming-messages-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          callback: (payload) {
            _onIncomingMessage(payload.newRecord, userId);
          },
        )
        .subscribe();
  }

  Future<void> stopListening() async {
    if (_channel != null) {
      await _db.removeChannel(_channel!);
    }
    _channel = null;
    _listeningUserId = null;
    _activeChatId = null;
  }

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
  }

  Future<void> _onIncomingMessage(
    Map<String, dynamic> mensaje,
    String currentUserId,
  ) async {
    if (!_notificationsAvailable) return;

    try {
      final senderId = mensaje['id_remitente']?.toString();
      final chatId = mensaje['id_chat']?.toString();
      if (senderId == null || chatId == null) return;

      // Ignorar mensajes propios.
      if (senderId == currentUserId) return;

      // Si el usuario está dentro de ese chat, no notificar.
      if (_activeChatId == chatId) return;

      String senderName = 'Nuevo mensaje';
      try {
        final perfil = await _db
            .from('perfiles')
            .select('nombre, username')
            .eq('id', senderId)
            .maybeSingle();
        senderName =
            (perfil?['nombre'] ?? perfil?['username'] ?? 'Nuevo mensaje')
                .toString();
      } catch (_) {
        // Si falla, usamos un nombre genérico y seguimos mostrando la notificación.
      }

      final body = _previewMessage(
        mensaje['tipo_contenido']?.toString(),
        mensaje['contenido']?.toString(),
      );

      final messageId = mensaje['id']?.toString();
      final notificationId =
          messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

      await _notifications.show(
        notificationId,
        senderName,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitlabs_messages',
            'Mensajes',
            channelDescription: 'Notificaciones de mensajes nuevos',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('MessageNotificationService error: $e');
    }
  }

  String _previewMessage(String? tipoContenido, String? contenido) {
    switch (tipoContenido) {
      case 'imagen':
        return 'Te ha enviado una foto';
      case 'video':
        return 'Te ha enviado un video';
      case 'audio':
        return 'Te ha enviado un audio';
      default:
        final text = (contenido ?? '').trim();
        return text.isEmpty ? 'Tienes un mensaje nuevo' : text;
    }
  }
}
