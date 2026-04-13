import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que mantiene los datos del perfil del usuario autenticado.
/// Se inicializa tras login y expone rol, nombre, userId, etc.
class SessionService {
  static String? _userId;
  static String? _role;
  static String? _username;
  static String? _email;
  static String? _avatarUrl;

  static String? get userId => _userId;
  static String? get role => _role;
  static String? get username => _username;
  static String? get email => _email;
  static String? get avatarUrl => _avatarUrl;

  static bool get isEntrenador => _role == 'entrenador';
  static bool get isCliente => _role == 'cliente';
  static bool get isLoggedIn => _userId != null;

  /// Carga el perfil desde Supabase. Llamar tras login exitoso.
  static Future<void> cargarPerfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      limpiar();
      return;
    }

    _userId = user.id;

    final data = await Supabase.instance.client
        .from('perfiles')
        .select('role, username, email, avatar_url')
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) {
      _role = data['role'] as String? ?? 'cliente';
      _username = data['username'] as String? ?? '';
      _email = data['email'] as String? ?? '';
      _avatarUrl = data['avatar_url'] as String?;
    }
  }

  /// Limpia la sesión (logout).
  static void limpiar() {
    _userId = null;
    _role = null;
    _username = null;
    _email = null;
    _avatarUrl = null;
  }
}
