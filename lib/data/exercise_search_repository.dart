import 'dart:convert';
import 'package:flutter/services.dart'; // <--- IMPORTANTE para rootBundle
import 'exercise_search_response.dart';
import 'exercise.dart'; // <--- Asegúrate de que el nombre sea correcto

class ExerciseSearchRepository {
  // Variable para guardar el JSON en memoria una vez cargado
  List<Exercise>? _allExercises;

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
        print(
          "✅ Base de datos local cargada: ${_allExercises!.length} ejercicios",
        );
      }

      // 2. FILTRADO (Buscamos por nombre o por músculo)
      final String searchQuery = query.toLowerCase();

      List<Exercise> filteredList = _allExercises!.where((exercise) {
        final nameMatch = exercise.name.toLowerCase().contains(searchQuery);
        final muscleMatch = exercise.primaryMuscles.any(
          (m) => m.toLowerCase().contains(searchQuery),
        );
        return nameMatch || muscleMatch;
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
      print("❌ Error cargando ejercicios locales: $e");
      return null;
    }
  }
}
