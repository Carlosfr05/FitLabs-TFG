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

  // ---------------------------------------------------------------------------
  // REALTIME & GUARDADO PROGRESIVO
  // ---------------------------------------------------------------------------

  /// Crea una sesión abierta al iniciar la rutina (finalizada = false).
  static Future<String> crearSesion({
    required String rutinaId,
    required String clientId,
  }) async {
    final sesion = await _db
        .from('sesiones_completadas')
        .insert({
          'rutina_id': rutinaId,
          'client_id': clientId,
          'finalizada': false,
        })
        .select('id')
        .single();
    return sesion['id'] as String;
  }

  /// Busca una sesión activa (no finalizada) de hoy para esta rutina/cliente.
  static Future<String?> fetchSesionActiva(
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
        .eq('finalizada', false)
        .maybeSingle();
    return data?['id'] as String?;
  }

  /// Upsert de un ejercicio completado individual (para guardado progresivo).
  static Future<void> upsertEjercicioCompletado({
    required String sesionId,
    required String idEjercicioRutina,
    required bool completado,
    double? pesoReal,
    int? repsReal,
  }) async {
    // Buscar si ya existe
    final existing = await _db
        .from('ejercicios_completados')
        .select('id')
        .eq('sesion_id', sesionId)
        .eq('id_ejercicio_rutina', idEjercicioRutina)
        .maybeSingle();

    if (existing != null) {
      await _db
          .from('ejercicios_completados')
          .update({
            'completado': completado,
            'peso_real': pesoReal,
            'reps_real': repsReal,
          })
          .eq('id', existing['id']);
    } else {
      await _db.from('ejercicios_completados').insert({
        'sesion_id': sesionId,
        'id_ejercicio_rutina': idEjercicioRutina,
        'completado': completado,
        'peso_real': pesoReal,
        'reps_real': repsReal,
      });
    }
  }

  /// Finaliza una sesión: marca finalizada = true y guarda las notas.
  static Future<void> finalizarSesion(String sesionId, String? notas) async {
    await _db
        .from('sesiones_completadas')
        .update({'finalizada': true, 'notas': notas})
        .eq('id', sesionId);
  }

  /// Suscripción Realtime a cambios en ejercicios_completados de una sesión.
  static RealtimeChannel suscribirseASesion(
    String sesionId,
    void Function(Map<String, dynamic> payload) onCambio,
  ) {
    return _db
        .channel('sesion-$sesionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ejercicios_completados',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sesion_id',
            value: sesionId,
          ),
          callback: (payload) {
            onCambio(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Suscripción Realtime a la tabla sesiones_completadas para un cliente.
  static RealtimeChannel suscribirseASesiones(
    String clientId,
    void Function(Map<String, dynamic> payload) onCambio,
  ) {
    return _db
        .channel('sesiones-$clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sesiones_completadas',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: clientId,
          ),
          callback: (payload) {
            onCambio(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Cancela una suscripción Realtime.
  static Future<void> cancelarSuscripcion(RealtimeChannel channel) async {
    await _db.removeChannel(channel);
  }

  /// Obtiene los ejercicios completados de una sesión activa (para restaurar estado).
  static Future<List<Map<String, dynamic>>> fetchEjerciciosCompletadosDeSesion(
    String sesionId,
  ) async {
    final data = await _db
        .from('ejercicios_completados')
        .select()
        .eq('sesion_id', sesionId);
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------------------------------------------------------------------
  // ESTADÍSTICAS
  // ---------------------------------------------------------------------------

  /// Porcentaje de cumplimiento: sesiones finalizadas vs rutinas asignadas.
  static Future<double> calcularCumplimiento(String clientId) async {
    final sesiones = await _db
        .from('sesiones_completadas')
        .select('id')
        .eq('client_id', clientId)
        .eq('finalizada', true);
    final rutinas = await _db
        .from('rutinas')
        .select('id')
        .eq('assigned_client_id', clientId);

    final totalRutinas = (rutinas as List).length;
    if (totalRutinas == 0) return 0;
    return (sesiones as List).length / totalRutinas * 100;
  }

  /// Volumen total semanal (suma de peso_real × reps_real de la última semana).
  static Future<double> calcularVolumenSemanal(String clientId) async {
    final desde = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String()
        .split('T')[0];

    final sesiones = await _db
        .from('sesiones_completadas')
        .select('id')
        .eq('client_id', clientId)
        .eq('finalizada', true)
        .gte('fecha', desde);

    double volumen = 0;
    for (final s in sesiones) {
      final ejercicios = await _db
          .from('ejercicios_completados')
          .select('peso_real, reps_real')
          .eq('sesion_id', s['id'])
          .eq('completado', true);
      for (final ej in ejercicios) {
        final peso = (ej['peso_real'] as num?)?.toDouble() ?? 0;
        final reps = (ej['reps_real'] as num?)?.toInt() ?? 0;
        volumen += peso * reps;
      }
    }
    return volumen;
  }

  /// Historial de volumen por sesión (para gráfica de progreso).
  static Future<List<Map<String, dynamic>>> fetchVolumenPorSesion(
    String clientId, {
    int limite = 10,
  }) async {
    final sesiones = await _db
        .from('sesiones_completadas')
        .select('id, fecha, creado_en')
        .eq('client_id', clientId)
        .eq('finalizada', true)
        .order('fecha', ascending: true)
        .limit(limite);

    final List<Map<String, dynamic>> resultado = [];
    for (final s in sesiones) {
      final ejercicios = await _db
          .from('ejercicios_completados')
          .select('peso_real, reps_real')
          .eq('sesion_id', s['id'])
          .eq('completado', true);

      double vol = 0;
      for (final ej in ejercicios) {
        final peso = (ej['peso_real'] as num?)?.toDouble() ?? 0;
        final reps = (ej['reps_real'] as num?)?.toInt() ?? 0;
        vol += peso * reps;
      }
      resultado.add({'fecha': s['fecha'], 'volumen': vol});
    }
    return resultado;
  }

  /// Ejercicios donde el cliente ha mejorado (más peso o más reps que la sesión anterior).
  static Future<List<Map<String, dynamic>>> fetchProgresoEjercicios(
    String clientId,
  ) async {
    final sesiones = await _db
        .from('sesiones_completadas')
        .select('id, fecha')
        .eq('client_id', clientId)
        .eq('finalizada', true)
        .order('fecha', ascending: false)
        .limit(2);

    if ((sesiones as List).length < 2) return [];

    final ultima = await _db
        .from('ejercicios_completados')
        .select('id_ejercicio_rutina, peso_real, reps_real')
        .eq('sesion_id', sesiones[0]['id'])
        .eq('completado', true);

    final anterior = await _db
        .from('ejercicios_completados')
        .select('id_ejercicio_rutina, peso_real, reps_real')
        .eq('sesion_id', sesiones[1]['id'])
        .eq('completado', true);

    final Map<String, Map<String, dynamic>> anteriorMap = {};
    for (final ej in anterior) {
      anteriorMap[ej['id_ejercicio_rutina']] = ej;
    }

    final List<Map<String, dynamic>> mejoras = [];
    for (final ej in ultima) {
      final prev = anteriorMap[ej['id_ejercicio_rutina']];
      if (prev != null) {
        final pesoAhora = (ej['peso_real'] as num?)?.toDouble() ?? 0;
        final pesoAntes = (prev['peso_real'] as num?)?.toDouble() ?? 0;
        final repsAhora = (ej['reps_real'] as num?)?.toInt() ?? 0;
        final repsAntes = (prev['reps_real'] as num?)?.toInt() ?? 0;

        if (pesoAhora > pesoAntes || repsAhora > repsAntes) {
          mejoras.add({
            'id_ejercicio_rutina': ej['id_ejercicio_rutina'],
            'peso_antes': pesoAntes,
            'peso_ahora': pesoAhora,
            'reps_antes': repsAntes,
            'reps_ahora': repsAhora,
          });
        }
      }
    }
    return mejoras;
  }
}
