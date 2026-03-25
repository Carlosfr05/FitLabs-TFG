import 'package:pantallas_fitlabs/data/exercise.dart';

class ExerciseSearchResponse {
  final List<Exercise> exercisesList;
  final int totalPages;

  ExerciseSearchResponse({
    required this.exercisesList,
    required this.totalPages,
  });

  factory ExerciseSearchResponse.fromJson(Map<String, dynamic> json) {
    List<Exercise> exercisesList = (json['data'] as List)
        .map((e) => Exercise.fromJson(e))
        .toList();

    int totalPages = json["metadata"]["totalPages"] ?? 1;
    return ExerciseSearchResponse(
      exercisesList: exercisesList,
      totalPages: totalPages,
    );
  }
}
