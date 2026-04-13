class Exercise {
  final String id;
  final String name;
  final String? force;
  final String level;
  final String? mechanic;
  final String? equipment;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String category;
  final List<String> images;

  Exercise({
    required this.id,
    required this.name,
    this.force,
    required this.level,
    this.mechanic,
    this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.category,
    required this.images,
  });

  // El método Factory para convertir el JSON en el objeto de Dart
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Exercise',
      force: json['force'], // Puede ser null
      level: json['level'] ?? 'beginner',
      mechanic: json['mechanic'], // Puede ser null
      equipment: json['equipment'] ?? 'None',
      // Convertimos los arrays del JSON a List<String> de Dart
      primaryMuscles: List<String>.from(json['primaryMuscles'] ?? []),
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      category: json['category'] ?? 'strength',
      images: List<String>.from(json['images'] ?? []),
    );
  }

  // Getter profesional: Construye la URL de la primera imagen para la lista
  String get thumbnailImageUrl {
    if (images.isEmpty) return "https://via.placeholder.com/150";

    // Eliminamos posibles espacios o comillas raras y montamos la URL de GitHub
    final path = images[0].trim();
    return "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$path";
  }

  // Getter extra: Por si quieres hacer el efecto de "pasado de fotos" en el detalle
  List<String> get allImageUrls {
    return images
        .map(
          (path) =>
              "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${path.trim()}",
        )
        .toList();
  }
}

class ExerciseSet {
  String? reps;
  double? weight;
  String? restTime; // Cambiado a String para match directo con tus inputs
  String? duration; // Cambiado a String para match directo con tus inputs

  ExerciseSet({this.reps, this.weight, this.restTime, this.duration});

  // Método para clonar el set (útil cuando editas para no modificar el original antes de guardar)
  ExerciseSet copyWith({
    String? reps,
    double? weight,
    String? restTime,
    String? duration,
  }) {
    return ExerciseSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      duration: duration ?? this.duration,
    );
  }
}

class ConfiguredExercise {
  final String instanceId; // ID único para esta "instancia" en la rutina
  final Exercise exercise;
  final List<ExerciseSet> sets;
  final String notes;

  ConfiguredExercise({
    String? id, // Si no pasas ID, creamos uno temporal
    required this.exercise,
    required this.sets,
    required this.notes,
  }) : instanceId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
