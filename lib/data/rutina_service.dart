import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para CRUD de rutinas y sus ejercicios.
class RutinaService {
  static final _db = Supabase.instance.client;

  /// Guarda una rutina completa (rutina + ejercicios) en Supabase.
  /// Devuelve el ID de la rutina creada.
  static Future<String> guardarRutina({
    required String creatorId,
    required String titulo,
    String? descripcion,
    String? clienteAsignadoId,
    String? fecha, // formato 'YYYY-MM-DD'
    String? horaInicio, // formato 'HH:MM'
    String? horaFin, // formato 'HH:MM'
    required List<Map<String, dynamic>> ejercicios,
  }) async {
    // 1. Insertar la rutina
    final rutinaData = <String, dynamic>{
      'creator_id': creatorId,
      'title': titulo,
      'description': descripcion,
      'assigned_client_id': clienteAsignadoId,
    };
    if (fecha != null) rutinaData['fecha'] = fecha;
    if (horaInicio != null) rutinaData['hora_inicio'] = horaInicio;
    if (horaFin != null) rutinaData['hora_fin'] = horaFin;

    final rutinaRow = await _db
        .from('rutinas')
        .insert(rutinaData)
        .select('id')
        .single();

    final rutinaId = rutinaRow['id'] as String;

    // 2. Insertar los ejercicios de la rutina
    if (ejercicios.isNotEmpty) {
      final rows = ejercicios.asMap().entries.map((entry) {
        final i = entry.key;
        final ej = entry.value;
        return {
          'id_rutina': rutinaId,
          'id_ejercicio_externo': ej['exerciseId'] as String,
          'serie': ej['series'] as int? ?? 1,
          'repeticiones': ej['reps'] as int?,
          'peso': ej['weight'] as double?,
          'duracion': ej['duration'] as int?,
          'descanso': ej['rest'] as int?,
          'orden': i + 1,
        };
      }).toList();

      await _db.from('ejercicios_rutina').insert(rows);
    }

    return rutinaId;
  }

  /// Obtiene las rutinas creadas por un entrenador.
  static Future<List<Map<String, dynamic>>> fetchRutinasEntrenador(
    String creatorId,
  ) async {
    final rows = await _db
        .from('rutinas')
        .select('*, cliente:perfiles!assigned_client_id(id, username, nombre)')
        .eq('creator_id', creatorId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Obtiene las rutinas asignadas a un cliente.
  static Future<List<Map<String, dynamic>>> fetchRutinasCliente(
    String clientId,
  ) async {
    final rows = await _db
        .from('rutinas')
        .select('*, creador:perfiles!creator_id(id, username, nombre)')
        .eq('assigned_client_id', clientId)
        .order('fecha', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Obtiene rutinas para una fecha concreta (para el calendario).
  static Future<List<Map<String, dynamic>>> fetchRutinasPorFecha(
    String userId,
    String fecha, // 'YYYY-MM-DD'
  ) async {
    final rows = await _db
        .from('rutinas')
        .select('*, cliente:perfiles!assigned_client_id(id, username, nombre)')
        .or('creator_id.eq.$userId,assigned_client_id.eq.$userId')
        .eq('fecha', fecha)
        .order('hora_inicio', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Obtiene las rutinas de hoy para el resumen del día.
  static Future<List<Map<String, dynamic>>> fetchRutinasHoy(
    String userId,
  ) async {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    return fetchRutinasPorFecha(userId, hoy);
  }

  /// Obtiene los ejercicios de una rutina concreta.
  static Future<List<Map<String, dynamic>>> fetchEjerciciosRutina(
    String rutinaId,
  ) async {
    final rows = await _db
        .from('ejercicios_rutina')
        .select()
        .eq('id_rutina', rutinaId)
        .order('orden', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Obtiene las rutinas asignadas a un cliente por un entrenador concreto.
  static Future<List<Map<String, dynamic>>> fetchRutinasDeCliente(
    String trainerId,
    String clientId,
  ) async {
    final rows = await _db
        .from('rutinas')
        .select()
        .eq('creator_id', trainerId)
        .eq('assigned_client_id', clientId)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Elimina una rutina y sus ejercicios (CASCADE).
  static Future<void> eliminarRutina(String rutinaId) async {
    await _db.from('rutinas').delete().eq('id', rutinaId);
  }
}
