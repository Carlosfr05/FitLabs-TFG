import 'package:flutter_test/flutter_test.dart';

/// Tests unitarios para SessionService y lógica de sesión.
/// Testeamos getters, propiedades computadas, y limpieza.

// Simulamos SessionService con la misma lógica
class MockSessionService {
  String? userId;
  String? role;
  String? username;
  String? email;
  String? avatarUrl;

  bool get isEntrenador => role == 'entrenador';
  bool get isCliente => role == 'cliente';
  bool get isLoggedIn => userId != null;

  void limpiar() {
    userId = null;
    role = null;
    username = null;
    email = null;
    avatarUrl = null;
  }
}

void main() {
  late MockSessionService session;

  setUp(() {
    session = MockSessionService();
  });

  group('SessionService - estado inicial', () {
    test('usuario no está logueado inicialmente', () {
      expect(session.isLoggedIn, isFalse);
    });

    test('no es entrenador ni cliente inicialmente', () {
      expect(session.isEntrenador, isFalse);
      expect(session.isCliente, isFalse);
    });

    test('todos los campos son null inicialmente', () {
      expect(session.userId, isNull);
      expect(session.role, isNull);
      expect(session.username, isNull);
      expect(session.email, isNull);
      expect(session.avatarUrl, isNull);
    });
  });

  group('SessionService - entrenador', () {
    setUp(() {
      session.userId = 'd4ace9cb-0096-4300-b60b-9be2bedb2934';
      session.role = 'entrenador';
      session.username = 'luis_trainer';
      session.email = 'luis@test.com';
    });

    test('isLoggedIn es true', () {
      expect(session.isLoggedIn, isTrue);
    });

    test('isEntrenador es true', () {
      expect(session.isEntrenador, isTrue);
    });

    test('isCliente es false', () {
      expect(session.isCliente, isFalse);
    });
  });

  group('SessionService - cliente', () {
    setUp(() {
      session.userId = '355d6d0c-5410-4225-8d4b-f60ff970ca4c';
      session.role = 'cliente';
      session.username = 'carlos_client';
      session.email = 'carlos@test.com';
    });

    test('isLoggedIn es true', () {
      expect(session.isLoggedIn, isTrue);
    });

    test('isCliente es true', () {
      expect(session.isCliente, isTrue);
    });

    test('isEntrenador es false', () {
      expect(session.isEntrenador, isFalse);
    });
  });

  group('SessionService - limpiar (logout)', () {
    test('limpia todos los campos', () {
      session.userId = 'test-id';
      session.role = 'entrenador';
      session.username = 'test_user';
      session.email = 'test@test.com';
      session.avatarUrl = 'https://example.com/avatar.jpg';

      session.limpiar();

      expect(session.userId, isNull);
      expect(session.role, isNull);
      expect(session.username, isNull);
      expect(session.email, isNull);
      expect(session.avatarUrl, isNull);
    });

    test('isLoggedIn es false tras limpiar', () {
      session.userId = 'test-id';
      session.limpiar();
      expect(session.isLoggedIn, isFalse);
    });

    test('roles son false tras limpiar', () {
      session.role = 'entrenador';
      session.limpiar();
      expect(session.isEntrenador, isFalse);
      expect(session.isCliente, isFalse);
    });
  });

  group('SessionService - roles edge cases', () {
    test('rol desconocido no es ni entrenador ni cliente', () {
      session.role = 'admin';
      expect(session.isEntrenador, isFalse);
      expect(session.isCliente, isFalse);
    });

    test('rol vacío no es ni entrenador ni cliente', () {
      session.role = '';
      expect(session.isEntrenador, isFalse);
      expect(session.isCliente, isFalse);
    });
  });
}
