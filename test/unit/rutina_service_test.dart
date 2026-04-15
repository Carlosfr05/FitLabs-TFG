import 'package:flutter_test/flutter_test.dart';

/// Tests unitarios para la lógica de RutinaService (rama Luis).
/// Testeamos la lógica de construcción de datos y validaciones.

// Simula la lógica de actualizarRutina: solo incluye campos no-null en el update
Map<String, dynamic> buildRutinaUpdateData({
  String? titulo,
  String? descripcion,
  String? fecha,
  String? horaInicio,
  String? horaFin,
}) {
  final data = <String, dynamic>{};
  if (titulo != null) data['title'] = titulo;
  if (descripcion != null) data['description'] = descripcion;
  if (fecha != null) data['fecha'] = fecha;
  if (horaInicio != null) data['hora_inicio'] = horaInicio;
  if (horaFin != null) data['hora_fin'] = horaFin;
  return data;
}

// Simula la lógica de actualizarEjercicioRutina
Map<String, dynamic> buildEjercicioUpdateData({
  int? series,
  int? repeticiones,
  double? peso,
  int? descanso,
}) {
  final data = <String, dynamic>{};
  if (series != null) data['serie'] = series;
  if (repeticiones != null) data['repeticiones'] = repeticiones;
  if (peso != null) data['peso'] = peso;
  if (descanso != null) data['descanso'] = descanso;
  return data;
}

// Simula la construcción de filas de ejercicios para inserción
List<Map<String, dynamic>> buildEjercicioRows(
  String rutinaId,
  List<Map<String, dynamic>> ejercicios,
) {
  return ejercicios.asMap().entries.map((entry) {
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
}

// Simula fetchRutinasPorMes: cálculo de rango de fechas
Map<String, String> calcularRangoMes(DateTime month) {
  final inicio = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final fin =
      '${month.year}-${month.month.toString().padLeft(2, '0')}-$lastDay';
  return {'inicio': inicio, 'fin': fin};
}

void main() {
  group('RutinaService - buildRutinaUpdateData', () {
    test('todos los campos null → mapa vacío', () {
      final data = buildRutinaUpdateData();
      expect(data, isEmpty);
    });

    test('solo título → solo title en mapa', () {
      final data = buildRutinaUpdateData(titulo: 'Full Body');
      expect(data, {'title': 'Full Body'});
    });

    test('todos los campos → mapa completo', () {
      final data = buildRutinaUpdateData(
        titulo: 'Upper Body',
        descripcion: 'Rutina de tren superior',
        fecha: '2026-04-15',
        horaInicio: '10:00',
        horaFin: '11:00',
      );
      expect(data.length, equals(5));
      expect(data['title'], equals('Upper Body'));
      expect(data['fecha'], equals('2026-04-15'));
    });

    test('campos parciales → solo esos campos', () {
      final data = buildRutinaUpdateData(titulo: 'Test', horaInicio: '09:30');
      expect(data.length, equals(2));
      expect(data.containsKey('description'), isFalse);
      expect(data.containsKey('fecha'), isFalse);
    });
  });

  group('RutinaService - buildEjercicioUpdateData', () {
    test('todos null → mapa vacío', () {
      expect(buildEjercicioUpdateData(), isEmpty);
    });

    test('solo peso → mapa con peso', () {
      final data = buildEjercicioUpdateData(peso: 25.0);
      expect(data, {'peso': 25.0});
    });

    test('series y reps', () {
      final data = buildEjercicioUpdateData(series: 4, repeticiones: 12);
      expect(data, {'serie': 4, 'repeticiones': 12});
    });

    test('todos los campos', () {
      final data = buildEjercicioUpdateData(
        series: 3,
        repeticiones: 10,
        peso: 20.0,
        descanso: 60,
      );
      expect(data.length, equals(4));
    });
  });

  group('RutinaService - buildEjercicioRows', () {
    test('lista vacía devuelve lista vacía', () {
      expect(buildEjercicioRows('rutina-1', []), isEmpty);
    });

    test('genera filas con orden correcto (1-indexed)', () {
      final ejercicios = [
        {
          'exerciseId': 'ex1',
          'series': 3,
          'reps': 10,
          'weight': 20.0,
          'rest': 60,
          'duration': null,
        },
        {
          'exerciseId': 'ex2',
          'series': 4,
          'reps': 8,
          'weight': 30.0,
          'rest': 90,
          'duration': null,
        },
      ];
      final rows = buildEjercicioRows('rutina-1', ejercicios);

      expect(rows.length, equals(2));
      expect(rows[0]['orden'], equals(1));
      expect(rows[1]['orden'], equals(2));
      expect(rows[0]['id_rutina'], equals('rutina-1'));
      expect(rows[0]['id_ejercicio_externo'], equals('ex1'));
      expect(rows[1]['serie'], equals(4));
    });

    test('series default es 1 si no se proporciona', () {
      final ejercicios = [
        {
          'exerciseId': 'ex1',
          'reps': 10,
          'weight': null,
          'rest': null,
          'duration': null,
        },
      ];
      final rows = buildEjercicioRows('rutina-1', ejercicios);
      expect(rows[0]['serie'], equals(1));
    });
  });

  group('RutinaService - calcularRangoMes', () {
    test('enero tiene 31 días', () {
      final rango = calcularRangoMes(DateTime(2026, 1, 15));
      expect(rango['inicio'], equals('2026-01-01'));
      expect(rango['fin'], equals('2026-01-31'));
    });

    test('febrero 2026 tiene 28 días (no bisiesto)', () {
      final rango = calcularRangoMes(DateTime(2026, 2, 1));
      expect(rango['inicio'], equals('2026-02-01'));
      expect(rango['fin'], equals('2026-02-28'));
    });

    test('febrero 2028 tiene 29 días (bisiesto)', () {
      final rango = calcularRangoMes(DateTime(2028, 2, 1));
      expect(rango['inicio'], equals('2028-02-01'));
      expect(rango['fin'], equals('2028-02-29'));
    });

    test('abril tiene 30 días', () {
      final rango = calcularRangoMes(DateTime(2026, 4, 15));
      expect(rango['inicio'], equals('2026-04-01'));
      expect(rango['fin'], equals('2026-04-30'));
    });

    test('diciembre tiene 31 días', () {
      final rango = calcularRangoMes(DateTime(2026, 12, 1));
      expect(rango['inicio'], equals('2026-12-01'));
      expect(rango['fin'], equals('2026-12-31'));
    });

    test('formato correcto con padding de ceros', () {
      final rango = calcularRangoMes(DateTime(2026, 3, 1));
      expect(rango['inicio'], equals('2026-03-01'));
      expect(rango['fin'], equals('2026-03-31'));
    });
  });

  group('RutinaService - ClienteService lógica de búsqueda', () {
    // Simulamos la lógica de búsqueda por query con ilike
    bool matchesQuery(String nombre, String username, String query) {
      final q = query.toLowerCase();
      return nombre.toLowerCase().contains(q) ||
          username.toLowerCase().contains(q);
    }

    test('busca por nombre parcial', () {
      expect(matchesQuery('Carlos Fraidias', 'carlitos', 'carlos'), isTrue);
    });

    test('busca por username parcial', () {
      expect(matchesQuery('Carlos Fraidias', 'carlitos', 'carlit'), isTrue);
    });

    test('no encuentra si no coincide', () {
      expect(matchesQuery('Carlos Fraidias', 'carlitos', 'luis'), isFalse);
    });

    test('búsqueda case insensitive', () {
      expect(matchesQuery('Carlos Fraidias', 'carlitos', 'CARLOS'), isTrue);
    });
  });
}
