import 'package:pantallas_fitlabs/data/exercise.dart';
import 'dart:convert';

class ExerciseSearchResponse {
  final List<Exercise> exercisesList;

  ExerciseSearchResponse({required this.exercisesList});

  factory ExerciseSearchResponse.fromJson(Map<String, dynamic> json) {
    List<Exercise> exercisesList = (json['data'] as List)
        .map((e) => Exercise.fromJson(e))
        .toList();
    return ExerciseSearchResponse(exercisesList: exercisesList);
  }
}
