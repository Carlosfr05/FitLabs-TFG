class Exercise {
  final String id;
  final String name;
  final String gifUrl;
  final List<String> targetMuscles;
  final List<String> equipments;
  final List<String> bodyParts;
  final List<String> instructions;
  Exercise({
    required this.id,
    required this.name,
    required this.gifUrl,
    required this.targetMuscles,
    required this.equipments,
    required this.bodyParts,
    required this.instructions,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['exerciseId'],
      name: json['name'],
      gifUrl: json['gifUrl'],
      targetMuscles: List<String>.from(json['targetMuscles']),
      equipments: List<String>.from(json['equipments']),
      bodyParts: List<String>.from(json['bodyParts']),
      instructions: List<String>.from(json['instructions']),
    );
  }
}
