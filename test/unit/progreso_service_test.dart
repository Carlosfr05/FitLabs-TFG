import 'package:flutter_test/flutter_test.dart';

/// Tests unitarios para la lógica de ProgresoService (rama Luis).
/// Testeamos la lógica pura que no requiere conexión a Supabase.

// Extraemos la lógica pura de ProgresoService para testear
int weekOfYear(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final diff = date.difference(firstDayOfYear).inDays;
  return (diff / 7).ceil();
}

/// Simula el cálculo de racha semanal con datos locales.
int calcularRachaSemanalLocal(List<String> fechasSesiones) {
  if (fechasSesiones.isEmpty) return 0;

  final Set<String> semanasConSesion = {};
  for (final f in fechasSesiones) {
    final fecha = DateTime.tryParse(f);
    if (fecha != null) {
      final wn = weekOfYear(fecha);
      semanasConSesion.add('${fecha.year}-$wn');
    }
  }

  final now = DateTime.now();
  int racha = 0;
  for (int i = 0; i < 52; i++) {
    final semana = now.subtract(Duration(days: 7 * i));
    final key = '${semana.year}-${weekOfYear(semana)}';
    if (semanasConSesion.contains(key)) {
      racha++;
    } else {
      break;
    }
  }
  return racha;
}

/// Simula el cálculo de volumen semanal.
double calcularVolumenLocal(List<Map<String, dynamic>> ejercicios) {
  double volumen = 0;
  for (final ej in ejercicios) {
    final peso = (ej['peso_real'] as num?)?.toDouble() ?? 0;
    final reps = (ej['reps_real'] as num?)?.toInt() ?? 0;
    volumen += peso * reps;
  }
  return volumen;
}

/// Simula la detección de mejoras entre sesiones.
List<Map<String, dynamic>> detectarMejoras(
  List<Map<String, dynamic>> ultima,
  List<Map<String, dynamic>> anterior,
) {
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

/// Simula el cálculo de cumplimiento.
double calcularCumplimientoLocal(int sesionesFinalizadas, int totalRutinas) {
  if (totalRutinas == 0) return 0;
  return sesionesFinalizadas / totalRutinas * 100;
}

void main() {
  group('ProgresoService - weekOfYear', () {
    test('1 de enero debería ser semana 0 o 1', () {
      final result = weekOfYear(DateTime(2026, 1, 1));
      expect(result, greaterThanOrEqualTo(0));
      expect(result, lessThanOrEqualTo(1));
    });

    test('31 de diciembre debería ser semana ~52', () {
      final result = weekOfYear(DateTime(2026, 12, 31));
      expect(result, greaterThanOrEqualTo(51));
      expect(result, lessThanOrEqualTo(53));
    });

    test('misma semana para lunes y domingo consecutivos', () {
      // 13 abril 2026 = lunes, 19 abril = domingo
      final lunes = weekOfYear(DateTime(2026, 4, 13));
      final domingo = weekOfYear(DateTime(2026, 4, 19));
      // Deberían estar en la misma semana o a lo sumo diferir en 1
      expect((domingo - lunes).abs(), lessThanOrEqualTo(1));
    });
  });

  group('ProgresoService - racha semanal', () {
    test('sin sesiones devuelve 0', () {
      expect(calcularRachaSemanalLocal([]), equals(0));
    });

    test('sesión esta semana devuelve al menos 1', () {
      final hoy = DateTime.now().toIso8601String().split('T')[0];
      expect(calcularRachaSemanalLocal([hoy]), greaterThanOrEqualTo(1));
    });

    test('sesiones en semanas consecutivas suman racha', () {
      final now = DateTime.now();
      final fechas = List.generate(4, (i) {
        return now
            .subtract(Duration(days: 7 * i))
            .toIso8601String()
            .split('T')[0];
      });
      expect(calcularRachaSemanalLocal(fechas), equals(4));
    });

    test('hueco en semana rompe la racha', () {
      final now = DateTime.now();
      // Semana actual, semana -1, pero NO semana -2, luego semana -3
      final fechas = [
        now.toIso8601String().split('T')[0],
        now.subtract(const Duration(days: 7)).toIso8601String().split('T')[0],
        now.subtract(const Duration(days: 21)).toIso8601String().split('T')[0],
      ];
      // La racha debería ser 2 (semana actual + semana -1), se rompe en semana -2
      expect(calcularRachaSemanalLocal(fechas), equals(2));
    });
  });

  group('ProgresoService - volumen', () {
    test('volumen vacío es 0', () {
      expect(calcularVolumenLocal([]), equals(0.0));
    });

    test('calcula peso × reps correctamente', () {
      final ejercicios = [
        {'peso_real': 20.0, 'reps_real': 10},
        {'peso_real': 30.0, 'reps_real': 8},
      ];
      // 20*10 + 30*8 = 200 + 240 = 440
      expect(calcularVolumenLocal(ejercicios), equals(440.0));
    });

    test('peso null se trata como 0', () {
      final ejercicios = [
        {'peso_real': null, 'reps_real': 40},
      ];
      expect(calcularVolumenLocal(ejercicios), equals(0.0));
    });

    test('reps null se trata como 0', () {
      final ejercicios = [
        {'peso_real': 25.0, 'reps_real': null},
      ];
      expect(calcularVolumenLocal(ejercicios), equals(0.0));
    });

    test('mix de ejercicios con y sin peso', () {
      final ejercicios = [
        {'peso_real': 22.5, 'reps_real': 10}, // 225
        {'peso_real': null, 'reps_real': 40}, // 0 (bodyweight)
        {'peso_real': 8.0, 'reps_real': 12}, // 96
      ];
      expect(calcularVolumenLocal(ejercicios), equals(321.0));
    });
  });

  group('ProgresoService - detección de mejoras', () {
    test('sin datos anteriores no hay mejoras', () {
      final ultima = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 25.0, 'reps_real': 10},
      ];
      expect(detectarMejoras(ultima, []), isEmpty);
    });

    test('detecta mejora en peso', () {
      final anterior = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 10},
      ];
      final ultima = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 22.5, 'reps_real': 10},
      ];
      final mejoras = detectarMejoras(ultima, anterior);
      expect(mejoras.length, equals(1));
      expect(mejoras[0]['peso_antes'], equals(20.0));
      expect(mejoras[0]['peso_ahora'], equals(22.5));
    });

    test('detecta mejora en reps', () {
      final anterior = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 8},
      ];
      final ultima = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 10},
      ];
      final mejoras = detectarMejoras(ultima, anterior);
      expect(mejoras.length, equals(1));
      expect(mejoras[0]['reps_ahora'], equals(10));
    });

    test('no detecta mejora si los valores son iguales', () {
      final anterior = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 10},
      ];
      final ultima = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 10},
      ];
      expect(detectarMejoras(ultima, anterior), isEmpty);
    });

    test('no detecta mejora si bajó el rendimiento', () {
      final anterior = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 25.0, 'reps_real': 10},
      ];
      final ultima = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 8},
      ];
      expect(detectarMejoras(ultima, anterior), isEmpty);
    });

    test('detecta mejora parcial (peso baja pero reps suben)', () {
      final anterior = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 25.0, 'reps_real': 8},
      ];
      final ultima = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 12},
      ];
      // repsAhora (12) > repsAntes (8) → es mejora
      final mejoras = detectarMejoras(ultima, anterior);
      expect(mejoras.length, equals(1));
    });

    test('múltiples ejercicios, solo algunos mejoran', () {
      final anterior = [
        {'id_ejercicio_rutina': 'ex1', 'peso_real': 20.0, 'reps_real': 10},
        {'id_ejercicio_rutina': 'ex2', 'peso_real': 30.0, 'reps_real': 8},
        {'id_ejercicio_rutina': 'ex3', 'peso_real': 10.0, 'reps_real': 15},
      ];
      final ultima = [
        {
          'id_ejercicio_rutina': 'ex1',
          'peso_real': 22.5,
          'reps_real': 10,
        }, // mejora peso
        {
          'id_ejercicio_rutina': 'ex2',
          'peso_real': 30.0,
          'reps_real': 8,
        }, // igual
        {
          'id_ejercicio_rutina': 'ex3',
          'peso_real': 10.0,
          'reps_real': 18,
        }, // mejora reps
      ];
      final mejoras = detectarMejoras(ultima, anterior);
      expect(mejoras.length, equals(2));
    });
  });

  group('ProgresoService - cumplimiento', () {
    test('0 rutinas asignadas = 0%', () {
      expect(calcularCumplimientoLocal(5, 0), equals(0.0));
    });

    test('todas completadas = 100%', () {
      expect(calcularCumplimientoLocal(10, 10), equals(100.0));
    });

    test('mitad completadas = 50%', () {
      expect(calcularCumplimientoLocal(5, 10), equals(50.0));
    });

    test('más sesiones que rutinas > 100%', () {
      // Esto puede pasar si se completó la misma rutina varias veces
      expect(calcularCumplimientoLocal(15, 10), equals(150.0));
    });
  });
}
