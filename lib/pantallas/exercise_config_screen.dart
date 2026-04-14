import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';

class ExerciseConfigScreen extends StatefulWidget {
  final Exercise exercise;
  final ConfiguredExercise? existingConfig;

  const ExerciseConfigScreen({
    super.key,
    required this.exercise,
    this.existingConfig,
  });

  @override
  State<ExerciseConfigScreen> createState() => _ExerciseConfigScreenState();
}

class _ExerciseConfigScreenState extends State<ExerciseConfigScreen> {
  List<ExerciseSet> exerciseSets = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si venimos de editar, cargamos los datos existentes
    if (widget.existingConfig != null) {
      // Usamos List.from para crear una copia y no mutar el original directamente
      exerciseSets = List.from(widget.existingConfig!.sets);
      _commentController.text = widget.existingConfig!.notes;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- FORMULARIO PARA CREAR/EDITAR SERIE ---
  void _showSetForm({ExerciseSet? existingSet, int? index}) {
    final repsController = TextEditingController(text: existingSet?.reps ?? '');
    final weightController = TextEditingController(
      text: existingSet?.weight?.toString() ?? '',
    );
    final restController = TextEditingController(
      text: existingSet?.restTime ?? '',
    );
    final durationController = TextEditingController(
      text: existingSet?.duration ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              existingSet == null ? 'Nueva Serie' : 'Editar Serie',
              style: const TextStyle(
                color: AppColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              repsController,
              'Repeticiones (ej: 8-10)',
              Icons.repeat,
            ),
            _buildField(
              weightController,
              'Peso (kg)',
              Icons.fitness_center,
              isNum: true,
            ),
            _buildField(
              restController,
              'Descanso (min:seg)',
              Icons.timer_outlined,
            ),
            _buildField(
              durationController,
              'Tiempo (ej: 45s)',
              Icons.hourglass_top,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLila,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (repsController.text.isEmpty &&
                      weightController.text.isEmpty &&
                      restController.text.isEmpty &&
                      durationController.text.isEmpty) {
                    Navigator.pop(context);
                    return;
                  }
                  setState(() {
                    final newSet = ExerciseSet(
                      reps: repsController.text,
                      weight: double.tryParse(weightController.text),
                      restTime: restController.text,
                      duration: durationController.text,
                    );
                    if (index != null) {
                      exerciseSets[index] = newSet;
                    } else {
                      exerciseSets.add(newSet);
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'GUARDAR SERIE',
                  style: TextStyle(
                    color: AppColors.bgBottom,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.accentLila, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.hintText, fontSize: 14),
          filled: true,
          fillColor: AppColors.searchBarBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 10, right: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Configurar Ejercicio',
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Imagen
                    Container(
                      height: 120,
                      margin: const EdgeInsets.symmetric(vertical: 15),
                      child: Image.network(
                        widget.exercise.allImageUrls.first,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.fitness_center,
                              size: 80,
                              color: Colors.white24,
                            ),
                      ),
                    ),
                    Text(
                      widget.exercise.name,
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Listado de Sets
                    if (exerciseSets.isEmpty)
                      _buildEmptyState()
                    else
                      ...exerciseSets.asMap().entries.map(
                        (e) => _buildSetCard(e.value, e.key),
                      ),

                    _buildAddSetButton(),
                    _buildCommentSection(),
                    _buildCreateExerciseButton(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () => _showSetForm(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.accentLila.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.accentLila.withValues(alpha: 0.4),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.accentLila),
              SizedBox(width: 10),
              Text(
                'AÑADIR NUEVA SERIE',
                style: TextStyle(
                  color: AppColors.accentLila,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.add_task, color: AppColors.accentLila, size: 40),
          SizedBox(height: 10),
          Text(
            'Crea un set para este ejercicio',
            style: TextStyle(
              color: AppColors.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetCard(ExerciseSet set, int index) {
    bool hasReps = set.reps != null && set.reps!.trim().isNotEmpty;
    bool hasWeight = set.weight != null;
    bool hasRest = set.restTime != null && set.restTime!.trim().isNotEmpty;
    bool hasDuration = set.duration != null && set.duration!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chatCardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accentLila.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accentLila,
          radius: 12,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.bgBottom,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${hasReps ? "${set.reps} reps" : ""}${hasReps && hasWeight ? " • " : ""}${hasWeight ? "${set.weight} kg" : ""}${!hasReps && !hasWeight ? "Serie sin datos" : ""}',
          style: const TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: (hasRest || hasDuration)
            ? Text(
                '${hasRest ? "Descanso: ${set.restTime}" : ""}${hasRest && hasDuration ? " • " : ""}${hasDuration ? "Tiempo: ${set.duration}" : ""}',
                style: const TextStyle(
                  color: AppColors.subTextColor,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- NUEVO BOTÓN DUPLICAR ---
            IconButton(
              icon: const Icon(
                Icons.content_copy, // Icono de duplicar/copiar
                color: AppColors.accentLila,
                size: 18,
              ),
              onPressed: () => _duplicateSet(set, index),
              tooltip: 'Duplicar serie',
            ),

            // --- BOTÓN EDITAR ---
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.dimmedColor,
                size: 20,
              ),
              onPressed: () => _showSetForm(existingSet: set, index: index),
            ),

            // --- BOTÓN BORRAR (con la confirmación que hicimos antes) ---
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.accentRed,
                size: 20,
              ),
              onPressed: () async {
                final confirm = await _showConfirmDeleteDialog(
                  context,
                  title: 'Eliminar Serie',
                  message: '¿Estás seguro de que quieres eliminar esta serie?',
                );
                if (confirm == true) {
                  setState(() => exerciseSets.removeAt(index));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTAS DEL ENTRENADOR',
            style: TextStyle(
              color: AppColors.accentLila,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.chatCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.accentLila.withValues(alpha: 0.1),
              ),
            ),
            child: TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textColor, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ej: Mantener la espalda recta...',
                hintStyle: TextStyle(color: AppColors.hintText, fontSize: 13),
                contentPadding: EdgeInsets.all(15),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateExerciseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accentLila, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () {
            if (exerciseSets.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Añade al menos una serie para finalizar"),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }

            // Mantenemos el ID si ya existía para que la lista principal sepa cuál actualizar
            final finalResult = ConfiguredExercise(
              id: widget.existingConfig?.instanceId,
              exercise: widget.exercise,
              sets: List.from(exerciseSets),
              notes: _commentController.text,
            );

            Navigator.pop(context, finalResult);
          },
          child: const Text(
            'FINALIZAR CONFIGURACIÓN',
            style: TextStyle(
              color: AppColors.accentLila,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDeleteDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'ATRÁS',
              style: TextStyle(color: AppColors.dimmedColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(
                color: AppColors.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _duplicateSet(ExerciseSet set, int index) {
    setState(() {
      // Creamos una copia exacta del set actual
      final duplicatedSet = ExerciseSet(
        reps: set.reps,
        weight: set.weight,
        restTime: set.restTime,
        duration: set.duration,
      );

      // Lo insertamos justo debajo del original para que el usuario no lo pierda de vista
      exerciseSets.insert(index + 1, duplicatedSet);
    });

    // Opcional: Un feedback rápido
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Serie duplicada"),
        duration: Duration(milliseconds: 800),
        backgroundColor: AppColors.accentLila,
      ),
    );
  }
}
