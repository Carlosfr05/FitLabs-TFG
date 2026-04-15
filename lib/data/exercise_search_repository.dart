import 'dart:convert';
import 'package:flutter/services.dart'; // <--- IMPORTANTE para rootBundle
import 'exercise_search_response.dart';
import 'exercise.dart'; // <--- Asegúrate de que el nombre sea correcto

class ExerciseSearchRepository {
  // Variable para guardar el JSON en memoria una vez cargado
  List<Exercise>? _allExercises;

  static const Map<String, String> _esToEnTerms = {
    'abdominales': 'abdominals',
    'abdominal': 'abdominals',
    'pecho': 'chest',
    'espalda': 'lats',
    'hombro': 'shoulders',
    'hombros': 'shoulders',
    'biceps': 'biceps',
    'triceps': 'triceps',
    'antebrazo': 'forearms',
    'antebrazos': 'forearms',
    'cuadriceps': 'quadriceps',
    'isquiotibiales': 'hamstrings',
    'gemelos': 'calves',
    'gluteos': 'glutes',
    'aductores': 'adductors',
    'abductores': 'abductors',
    'trapecio': 'traps',
    'cuello': 'neck',
    'lumbar': 'lower back',
    'espalda baja': 'lower back',
    'espalda alta': 'middle back',
    'cardio': 'cardio',
    'fuerza': 'strength',
    'estiramiento': 'stretching',
    'plyometria': 'plyometrics',
    'levantamiento olimpico': 'olympic weightlifting',
    'maquina': 'machine',
    'barra': 'barbell',
    'mancuerna': 'dumbbell',
    'mancuernas': 'dumbbell',
    'peso corporal': 'body only',
    'sin equipo': 'body only',
    'cable': 'cable',
    'kettlebell': 'kettlebells',
    'rodillo': 'foam roll',
  };

  static const Map<String, List<String>> _enToEsAliases = {
    'abdominals': ['abdominales'],
    'chest': ['pecho', 'pectoral'],
    'lats': ['espalda', 'dorsales'],
    'middle back': ['espalda media'],
    'lower back': ['lumbar', 'espalda baja'],
    'traps': ['trapecio'],
    'shoulders': ['hombros', 'hombro'],
    'biceps': ['biceps'],
    'triceps': ['triceps'],
    'forearms': ['antebrazos', 'antebrazo'],
    'quadriceps': ['cuadriceps'],
    'hamstrings': ['isquiotibiales'],
    'calves': ['gemelos'],
    'glutes': ['gluteos'],
    'adductors': ['aductores'],
    'abductors': ['abductores'],
    'strength': ['fuerza'],
    'stretching': ['estiramiento'],
    'cardio': ['cardio'],
    'machine': ['maquina'],
    'barbell': ['barra'],
    'dumbbell': ['mancuerna', 'mancuernas'],
    'body only': ['peso corporal', 'sin equipo'],
    'foam roll': ['rodillo'],
  };

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _replaceWholeWord(String input, String from, String to) {
    final regExp = RegExp('(^| )${RegExp.escape(from)}(?= |\$)');
    return input.replaceAllMapped(regExp, (m) {
      final prefix = m.group(1) ?? '';
      return '$prefix$to';
    });
  }

  Set<String> _buildQueryVariants(String query) {
    final normalizedOriginal = _normalize(query);
    if (normalizedOriginal.isEmpty) return {''};

    String translated = normalizedOriginal;
    final keys = _esToEnTerms.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final es in keys) {
      translated = _replaceWholeWord(translated, es, _esToEnTerms[es]!);
    }

    return {normalizedOriginal, _normalize(translated)};
  }

  String _exerciseSearchText(Exercise exercise) {
    final buffer = StringBuffer();

    void add(String value) {
      final normalized = _normalize(value);
      if (normalized.isNotEmpty) {
        buffer.write(normalized);
        buffer.write(' ');
      }
    }

    add(exercise.name);
    add(exercise.category);
    add(exercise.equipment ?? '');

    for (final m in exercise.primaryMuscles) {
      add(m);
      for (final alias in _enToEsAliases[m] ?? const <String>[]) {
        add(alias);
      }
    }

    for (final m in exercise.secondaryMuscles) {
      add(m);
      for (final alias in _enToEsAliases[m] ?? const <String>[]) {
        add(alias);
      }
    }

    for (final alias in _enToEsAliases[exercise.category] ?? const <String>[]) {
      add(alias);
    }
    for (final alias
        in _enToEsAliases[exercise.equipment ?? ''] ?? const <String>[]) {
      add(alias);
    }

    return buffer.toString();
  }

  bool _matchesVariant(String haystack, String variant) {
    if (variant.isEmpty) return false;
    if (haystack.contains(variant)) return true;

    final tokens = variant.split(' ').where((t) => t.isNotEmpty);
    return tokens.isNotEmpty && tokens.every(haystack.contains);
  }

  Future<ExerciseSearchResponse?> searchExercises(
    String query,
    int page,
  ) async {
    try {
      // 1. CARGAR EL ARCHIVO (Solo la primera vez)
      if (_allExercises == null) {
        final String response = await rootBundle.loadString(
          'assets/json/exercises.json',
        );
        final List<dynamic> decodedJson = jsonDecode(response);

        // Convertimos el JSON en nuestra lista de objetos Exercise
        _allExercises = decodedJson.map((e) => Exercise.fromJson(e)).toList();
      }

      // 2. FILTRADO (acepta búsqueda en inglés y español)
      final queryVariants = _buildQueryVariants(query);

      List<Exercise> filteredList = _allExercises!.where((exercise) {
        final haystack = _exerciseSearchText(exercise);
        for (final variant in queryVariants) {
          if (_matchesVariant(haystack, variant)) return true;
        }
        return false;
      }).toList();

      // 3. PAGINACIÓN MANUAL (Simulamos lo que hacía la API)
      int limit = 10;
      int start = (page - 1) * limit;
      int end = start + limit;

      // Control de errores en los índices
      if (start >= filteredList.length) {
        return ExerciseSearchResponse(exercisesList: [], totalPages: 0);
      }
      if (end > filteredList.length) end = filteredList.length;

      // 4. DEVOLVER EL RESULTADO
      List<Exercise> pagedList = filteredList.sublist(start, end);
      int totalPages = (filteredList.length / limit).ceil();

      return ExerciseSearchResponse(
        exercisesList: pagedList,
        totalPages: totalPages,
      );
    } catch (e) {
      return null;
    }
  }
}
