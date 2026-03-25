import 'package:http/http.dart' as http;
import 'exercise_search_response.dart';
import 'dart:convert';

class ExerciseSearchRepository {
  Future<ExerciseSearchResponse?> searchExercises(
    String query,
    int page,
  ) async {
    int offset = (page - 1) * 10;
    try {
      final response = await http.get(
        Uri.parse("https://exercisedb.dev/api/v1/exercises/search?q=$query&offset=$offset&limit=10"),
      );
      if (response.statusCode == 200) {
        var decodedJson = jsonDecode(response.body);
        ExerciseSearchResponse exerciseResponse =
            ExerciseSearchResponse.fromJson(decodedJson);
        return exerciseResponse;
      } else {
        return null;
      }
    } catch (e) {
      print("Error en la conexion: $e");
      return null;
    }
  }
}
