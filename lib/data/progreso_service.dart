import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para tracking de progreso: sesiones completadas y ejercicios realizados.
class ProgresoService {
  static final _db = Supabase.instance.client;

  /// Marca una rutina como completada por el cliente.
  /// Guarda la sesión y los ejercicios con peso/reps reales.
  static Future<String> completarRutina({
    required String rutinaId,
    required String clientId,
    String? notas,
    required List<Map<String, dynamic>> ejerciciosCompletados,
  }) async {
    // Crear sesión completada
    final sesion = await _db
        .from('sesiones_completadas')
        .insert({'rutina_id': rutinaId, 'client_id': clientId, 'notas': notas})
        .select('id')
        .single();

    final sesionId = sesion['id'] as String;

    // Guardar ejercicios completados
    if (ejerciciosCompletados.isNotEmpty) {
      final rows = ejerciciosCompletados.map((ej) {
        return {
          'sesion_id': sesionId,
          'id_ejercicio_rutina': ej['id_ejercicio_rutina'],
          'completado': ej['completado'] ?? true,
          'peso_real': ej['peso_real'],
          'reps_real': ej['reps_real'],
          'notas': ej['notas'],
        };
      }).toList();

      await _db.from('ejercicios_completados').insert(rows);
    }

    return sesionId;
  }

  /// Obtiene cuántas sesiones ha completado un cliente.
  static Future<int> contarSesionesCompletadas(String clientId) async {
    final data = await _db
        .from('sesiones_completadas')
        .select('id')
        .eq('client_id', clientId);
    return (data as List).length;
  }

  /// Obtiene la racha semanal (semanas consecutivas con al menos 1 sesión).
  static Future<int> calcularRachaSemanal(String clientId) async {
    final data = await _db
        .from('sesiones_completadas')
        .select('fecha')
        .eq('client_id', clientId)
        .order('fecha', ascending: false);

    if ((data as List).isEmpty) return 0;

    // Agrupar por número de semana
    final Set<String> semanasConSesion = {};
    for (final row in data) {
      final fecha = DateTime.tryParse(row['fecha'] ?? '');
      if (fecha != null) {
        // Clave: año-semana
        final weekNumber = _weekOfYear(fecha);
        semanasConSesion.add('${fecha.year}-$weekNumber');
      }
    }

    // Calcular racha desde la semana actual hacia atrás
    final now = DateTime.now();
    int racha = 0;
    for (int i = 0; i < 52; i++) {
      final semana = now.subtract(Duration(days: 7 * i));
      final key = '${semana.year}-${_weekOfYear(semana)}';
      if (semanasConSesion.contains(key)) {
        racha++;
      } else {
        break;
      }
    }

    return racha;
  }

  static int _weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDayOfYear).inDays;
    return (diff / 7).ceil();
  }

  /// Verifica si una rutina ya fue completada hoy por el cliente.
  static Future<bool> rutinaCompletadaHoy(
    String rutinaId,
    String clientId,
  ) async {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final data = await _db
        .from('sesiones_completadas')
        .select('id')
        .eq('rutina_id', rutinaId)
        .eq('client_id', clientId)
        .eq('fecha', hoy)
        .maybeSingle();
    return data != null;
  }

  /// Historial de sesiones completadas de un cliente (para el entrenador).
  static Future<List<Map<String, dynamic>>> fetchHistorialCliente(
    String clientId,
  ) async {
    final data = await _db
        .from('sesiones_completadas')
        .select('*, rutina:rutinas(id, title, fecha, hora_inicio, hora_fin)')
        .eq('client_id', clientId)
        .order('creado_en', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Obtiene el detalle de ejercicios completados de una sesión.
  static Future<List<Map<String, dynamic>>> fetchEjerciciosSesion(
    String sesionId,
  ) async {
    final data = await _db
        .from('ejercicios_completados')
        .select(
          '*, ejercicio:ejercicios_rutina(id_ejercicio_externo, serie, repeticiones, peso)',
        )
        .eq('sesion_id', sesionId);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Sesiones completadas en los últimos N días (para gráficas).
  static Future<List<Map<String, dynamic>>> fetchSesionesRecientes(
    String clientId,
    int dias,
  ) async {
    final desde = DateTime.now()
        .subtract(Duration(days: dias))
        .toIso8601String()
        .split('T')[0];
    final data = await _db
        .from('sesiones_completadas')
        .select('fecha, creado_en')
        .eq('client_id', clientId)
        .gte('fecha', desde)
        .order('fecha', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }
}
