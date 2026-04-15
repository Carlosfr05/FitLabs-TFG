import 'package:flutter_test/flutter_test.dart';

/// Tests unitarios para MessageNotificationService (rama Carlos).
/// Testeamos la lógica de preview de mensajes y filtrado.

// Extraemos la lógica pura de _previewMessage
String previewMessage(String? tipoContenido, String? contenido) {
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

// Extraemos la lógica de filtrado de mensajes propios/chat activo
bool shouldShowNotification({
  required String senderId,
  required String currentUserId,
  required String chatId,
  required String? activeChatId,
}) {
  if (senderId == currentUserId) return false;
  if (activeChatId == chatId) return false;
  return true;
}

// Lógica de preview de último mensaje en la lista de chats (ChatService)
String chatLastMessagePreview(String? contenido, String tipoContenido) {
  String preview = contenido ?? '';
  if (tipoContenido == 'imagen') preview = '📷 Foto';
  if (tipoContenido == 'video') preview = '🎥 Vídeo';
  if (tipoContenido == 'audio') preview = '🎙️ Audio';
  return preview;
}

// Verificamos isNetworkError
bool isNetworkError(String errorMsg) {
  final msg = errorMsg.toLowerCase();
  return msg.contains('failed host lookup') ||
      msg.contains('socketexception') ||
      msg.contains('no address associated with hostname');
}

void main() {
  group('MessageNotificationService - previewMessage', () {
    test('imagen muestra "Te ha enviado una foto"', () {
      expect(previewMessage('imagen', null), equals('Te ha enviado una foto'));
    });

    test('video muestra "Te ha enviado un video"', () {
      expect(previewMessage('video', null), equals('Te ha enviado un video'));
    });

    test('audio muestra "Te ha enviado un audio"', () {
      expect(previewMessage('audio', null), equals('Te ha enviado un audio'));
    });

    test('texto muestra el contenido', () {
      expect(previewMessage('texto', 'Hola qué tal'), equals('Hola qué tal'));
    });

    test('texto null muestra fallback', () {
      expect(previewMessage('texto', null), equals('Tienes un mensaje nuevo'));
    });

    test('texto vacío muestra fallback', () {
      expect(previewMessage('texto', ''), equals('Tienes un mensaje nuevo'));
    });

    test('texto solo espacios muestra fallback', () {
      expect(previewMessage('texto', '   '), equals('Tienes un mensaje nuevo'));
    });

    test('tipo null con contenido muestra contenido', () {
      expect(
        previewMessage(null, 'Mensaje de prueba'),
        equals('Mensaje de prueba'),
      );
    });

    test('tipo desconocido con contenido muestra contenido', () {
      expect(previewMessage('documento', 'adjunto.pdf'), equals('adjunto.pdf'));
    });
  });

  group('MessageNotificationService - filtrado de notificaciones', () {
    test('no notifica mensajes propios', () {
      expect(
        shouldShowNotification(
          senderId: 'user1',
          currentUserId: 'user1',
          chatId: 'chat1',
          activeChatId: null,
        ),
        isFalse,
      );
    });

    test('no notifica si el chat está activo', () {
      expect(
        shouldShowNotification(
          senderId: 'user2',
          currentUserId: 'user1',
          chatId: 'chat1',
          activeChatId: 'chat1',
        ),
        isFalse,
      );
    });

    test('notifica mensajes de otro usuario en chat inactivo', () {
      expect(
        shouldShowNotification(
          senderId: 'user2',
          currentUserId: 'user1',
          chatId: 'chat1',
          activeChatId: null,
        ),
        isTrue,
      );
    });

    test('notifica si el chat activo es diferente', () {
      expect(
        shouldShowNotification(
          senderId: 'user2',
          currentUserId: 'user1',
          chatId: 'chat1',
          activeChatId: 'chat2',
        ),
        isTrue,
      );
    });
  });

  group('ChatService - preview último mensaje', () {
    test('imagen muestra emoji foto', () {
      expect(chatLastMessagePreview(null, 'imagen'), equals('📷 Foto'));
    });

    test('video muestra emoji vídeo', () {
      expect(chatLastMessagePreview(null, 'video'), equals('🎥 Vídeo'));
    });

    test('audio muestra emoji audio', () {
      expect(chatLastMessagePreview(null, 'audio'), equals('🎙️ Audio'));
    });

    test('texto muestra contenido', () {
      expect(chatLastMessagePreview('Hola!', 'texto'), equals('Hola!'));
    });

    test('contenido null sin tipo especial muestra vacío', () {
      expect(chatLastMessagePreview(null, 'texto'), equals(''));
    });
  });

  group('ChatService - detección de error de red', () {
    test('detecta failed host lookup', () {
      expect(isNetworkError('Failed host lookup: example.com'), isTrue);
    });

    test('detecta SocketException', () {
      expect(isNetworkError('SocketException: Connection refused'), isTrue);
    });

    test('detecta no address', () {
      expect(isNetworkError('No address associated with hostname'), isTrue);
    });

    test('no detecta error genérico', () {
      expect(isNetworkError('Permission denied'), isFalse);
    });

    test('no detecta error vacío', () {
      expect(isNetworkError(''), isFalse);
    });

    test('detección es case-insensitive', () {
      expect(isNetworkError('SOCKETEXCEPTION: error'), isTrue);
    });
  });
}
