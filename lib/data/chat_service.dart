import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _db = Supabase.instance.client;

  /// Obtiene los chats del usuario con info del otro participante y último mensaje.
  static Future<List<Map<String, dynamic>>> fetchChats(String userId) async {
    // Chats donde el user es usuario1 o usuario2
    final chats = await _db
        .from('chats')
        .select('id, id_usuario1, id_usuario2, actualizado_en')
        .or('id_usuario1.eq.$userId,id_usuario2.eq.$userId')
        .order('actualizado_en', ascending: false);

    final List<Map<String, dynamic>> result = [];

    for (final chat in chats) {
      final otherUserId = chat['id_usuario1'] == userId
          ? chat['id_usuario2']
          : chat['id_usuario1'];

      // Info del otro usuario
      final perfil = await _db
          .from('perfiles')
          .select('id, username, nombre, avatar_url')
          .eq('id', otherUserId)
          .maybeSingle();

      // Último mensaje
      final lastMsg = await _db
          .from('mensajes')
          .select('contenido, creado_en, id_remitente, leido, tipo_contenido')
          .eq('id_chat', chat['id'])
          .order('creado_en', ascending: false)
          .limit(1)
          .maybeSingle();

      // Contar mensajes no leídos
      final unread = await _db
          .from('mensajes')
          .select('id')
          .eq('id_chat', chat['id'])
          .neq('id_remitente', userId)
          .eq('leido', false);

      String lastMessagePreview = lastMsg?['contenido'] ?? '';
      final lastTipo = lastMsg?['tipo_contenido']?.toString() ?? 'texto';
      if (lastTipo == 'imagen') lastMessagePreview = '📷 Foto';
      if (lastTipo == 'video') lastMessagePreview = '🎥 Vídeo';
      if (lastTipo == 'audio') lastMessagePreview = '🎙️ Audio';

      result.add({
        'chatId': chat['id'],
        'otherUserId': otherUserId,
        'nombre': perfil?['nombre'] ?? perfil?['username'] ?? 'Usuario',
        'avatarUrl': perfil?['avatar_url'],
        'lastMessage': lastMessagePreview,
        'lastMessageTime': lastMsg?['creado_en'],
        'lastSenderId': lastMsg?['id_remitente'],
        'unreadCount': (unread as List).length,
      });
    }

    return result;
  }

  /// Obtiene o crea un chat entre dos usuarios. Devuelve el chatId.
  static Future<String> getOrCreateChat(String userId1, String userId2) async {
    // Buscar chat existente
    final existing = await _db
        .from('chats')
        .select('id')
        .or(
          'and(id_usuario1.eq.$userId1,id_usuario2.eq.$userId2),and(id_usuario1.eq.$userId2,id_usuario2.eq.$userId1)',
        )
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    // Crear nuevo chat
    final newChat = await _db
        .from('chats')
        .insert({'id_usuario1': userId1, 'id_usuario2': userId2})
        .select('id')
        .single();

    return newChat['id'] as String;
  }

  /// Obtiene los mensajes de un chat, ordenados cronológicamente.
  static Future<List<Map<String, dynamic>>> fetchMensajes(String chatId) async {
    final data = await _db
        .from('mensajes')
        .select('id, id_remitente, contenido, leido, creado_en, tipo_contenido, media_url')
        .eq('id_chat', chatId)
        .order('creado_en', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Envía un mensaje y actualiza el timestamp del chat.
  static Future<void> enviarMensaje(
    String chatId,
    String senderId,
    String contenido,
  ) async {
    await _db.from('mensajes').insert({
      'id_chat': chatId,
      'id_remitente': senderId,
      'contenido': contenido,
      'tipo_contenido': 'texto',
    });

    await _db
        .from('chats')
        .update({'actualizado_en': DateTime.now().toIso8601String()})
        .eq('id', chatId);
  }

  /// Sube un archivo a Supabase Storage y devuelve la URL pública.
  static Future<String> subirArchivo(String chatId, File file, String extension) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$chatId/$timestamp.$extension';
    await _db.storage.from('chat-media').upload(path, file);
    return _db.storage.from('chat-media').getPublicUrl(path);
  }

  /// Envía un mensaje multimedia (foto, video, audio).
  static Future<void> enviarMensajeMultimedia({
    required String chatId,
    required String senderId,
    required String tipoContenido,
    required File archivo,
    required String extension,
    String? textoOpcional,
  }) async {
    final url = await subirArchivo(chatId, archivo, extension);
    await _db.from('mensajes').insert({
      'id_chat': chatId,
      'id_remitente': senderId,
      'contenido': textoOpcional,
      'tipo_contenido': tipoContenido,
      'media_url': url,
    });
    await _db
        .from('chats')
        .update({'actualizado_en': DateTime.now().toIso8601String()})
        .eq('id', chatId);
  }

  /// Marca como leídos los mensajes del otro usuario en un chat.
  static Future<void> marcarComoLeido(
    String chatId,
    String currentUserId,
  ) async {
    await _db
        .from('mensajes')
        .update({'leido': true})
        .eq('id_chat', chatId)
        .neq('id_remitente', currentUserId)
        .eq('leido', false);
  }

  /// Suscribirse a nuevos mensajes en un chat (Realtime).
  static RealtimeChannel suscribirseAMensajes(
    String chatId,
    void Function(Map<String, dynamic> mensaje) onNuevo,
  ) {
    return _db
        .channel('chat-$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_chat',
            value: chatId,
          ),
          callback: (payload) {
            onNuevo(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Suscribirse a cambios en la lista de chats del usuario (para actualizar la lista).
  static RealtimeChannel suscribirseAChats(
    String userId,
    void Function() onCambio,
  ) {
    return _db
        .channel('chats-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mensajes',
          callback: (_) {
            onCambio();
          },
        )
        .subscribe();
  }

  /// Cancela suscripción a un canal Realtime.
  static Future<void> cancelarSuscripcion(RealtimeChannel channel) async {
    await _db.removeChannel(channel);
  }
}
