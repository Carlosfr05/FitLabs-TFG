import 'package:pantallas_fitlabs/data/exercise.dart';

class ExerciseSearchResponse {
  final List<Exercise> exercisesList;
  final int totalPages;

  ExerciseSearchResponse({
    required this.exercisesList,
    required this.totalPages,
  });
}
