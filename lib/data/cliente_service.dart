import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestionar la relación entrenador ↔ cliente.
class ClienteService {
  static final _db = Supabase.instance.client;

  /// Obtiene los clientes vinculados a un entrenador (status='aceptado').
  /// Devuelve lista con datos del perfil del cliente.
  static Future<List<Map<String, dynamic>>> fetchMisClientes(
    String trainerId,
  ) async {
    final rows = await _db
        .from('clientes_entrenador')
        .select(
          'id, status, created_at, client:perfiles!client_id(id, username, nombre, email, avatar_url)',
        )
        .eq('trainer_id', trainerId)
        .eq('status', 'aceptado')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Busca un usuario por email para invitarlo como cliente.
  /// Devuelve el perfil o null si no existe.
  static Future<Map<String, dynamic>?> buscarUsuarioPorEmail(
    String email,
  ) async {
    final row = await _db
        .from('perfiles')
        .select('id, username, nombre, email, avatar_url, role')
        .eq('email', email)
        .eq('role', 'cliente')
        .maybeSingle();
    return row;
  }

  /// Busca usuarios cliente por nombre o username (estilo buscador).
  static Future<List<Map<String, dynamic>>> buscarClientesPorNombre(
    String query, {
    String? excludeUserId,
    int limit = 30,
  }) async {
    final baseQuery = _db
        .from('perfiles')
        .select('id, username, nombre, email, avatar_url, role')
        .eq('role', 'cliente')
        .or('nombre.ilike.%$query%,username.ilike.%$query%');

    final rows = excludeUserId != null && excludeUserId.isNotEmpty
        ? await baseQuery.neq('id', excludeUserId).limit(limit)
        : await baseQuery.limit(limit);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Busca un único usuario cliente por email exacto.
  static Future<Map<String, dynamic>?> buscarClientePorEmail(
    String email, {
    String? excludeUserId,
  }) async {
    final baseQuery = _db
        .from('perfiles')
        .select('id, username, nombre, email, avatar_url, role')
        .eq('role', 'cliente')
        .eq('email', email);

    final row = excludeUserId != null && excludeUserId.isNotEmpty
        ? await baseQuery.neq('id', excludeUserId).maybeSingle()
        : await baseQuery.maybeSingle();

    return row;
  }

  /// El entrenador envía una invitación a un cliente.
  /// Crea una fila en clientes_entrenador con status='pendiente'.
  static Future<void> invitarCliente({
    required String trainerId,
    required String clientId,
  }) async {
    // Verificar que no exista ya una relación
    final existe = await _db
        .from('clientes_entrenador')
        .select('id')
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId)
        .maybeSingle();

    if (existe != null) return; // Ya existe la relación

    await _db.from('clientes_entrenador').insert({
      'trainer_id': trainerId,
      'client_id': clientId,
      'status': 'aceptado', // Auto-aceptado por ahora
    });
  }

  /// El cliente acepta la invitación del entrenador.
  static Future<void> aceptarInvitacion(String relacionId) async {
    await _db
        .from('clientes_entrenador')
        .update({'status': 'aceptado'})
        .eq('id', relacionId);
  }

  /// Elimina la relación entrenador-cliente.
  static Future<void> eliminarCliente(String relacionId) async {
    await _db.from('clientes_entrenador').delete().eq('id', relacionId);
  }

  /// Obtiene invitaciones pendientes para un cliente.
  static Future<List<Map<String, dynamic>>> fetchInvitacionesPendientes(
    String clientId,
  ) async {
    final rows = await _db
        .from('clientes_entrenador')
        .select(
          'id, trainer:perfiles!trainer_id(id, username, nombre, avatar_url)',
        )
        .eq('client_id', clientId)
        .eq('status', 'pendiente');

    return List<Map<String, dynamic>>.from(rows);
  }
}
