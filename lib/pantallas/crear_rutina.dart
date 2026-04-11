import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/pantallas/exercise_config_screen.dart';

class CrearRutinaScreen extends StatefulWidget {
  const CrearRutinaScreen({super.key});

  @override
  State<CrearRutinaScreen> createState() => _CrearRutinaScreenState();
}

class _CrearRutinaScreenState extends State<CrearRutinaScreen> {
  List<ConfiguredExercise> listaEjerciciosConfigurados = [];
  final TextEditingController _tituloController = TextEditingController(
    text: "Sesión entrenamiento PUSH - hipertrofia",
  );
  // Nuevo controlador para el comentario general
  final TextEditingController _comentarioGeneralController =
      TextEditingController();

  @override
  void dispose() {
    _tituloController.dispose();
    _comentarioGeneralController.dispose();
    super.dispose();
  }

  void _abrirBuscador() async {
    final resultado = await Navigator.pushNamed(context, '/search-ejercicio');

    if (resultado != null && resultado is ConfiguredExercise) {
      setState(() {
        listaEjerciciosConfigurados.add(resultado);
      });
    }
  }

  Future<bool?> _showConfirmDeleteDialog(String exerciseName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondarySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar ejercicio?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se eliminará "$exerciseName" de la rutina, incluyendo todas sus series y notas. Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ATRÁS', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      _buildSelectorCliente(),
                      const SizedBox(height: 25),
                      _buildInputTitulo(),
                      const SizedBox(height: 30),

                      // --- LISTA DE EJERCICIOS ---
                      if (listaEjerciciosConfigurados.isEmpty)
                        _buildEmptyState()
                      else
                        ...listaEjerciciosConfigurados.map((ejercicio) {
                          return _buildExerciseCard(
                            ejercicio: ejercicio,
                            onDelete: () async {
                              final confirm = await _showConfirmDeleteDialog(
                                ejercicio.exercise.name,
                              );
                              if (confirm == true) {
                                setState(() {
                                  listaEjerciciosConfigurados.removeWhere(
                                    (e) => e.instanceId == ejercicio.instanceId,
                                  );
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${ejercicio.exercise.name} eliminado",
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.grey[800],
                                  ),
                                );
                              }
                            },
                            onInfo: () {
                              Navigator.pushNamed(
                                context,
                                '/exercise-detail',
                                arguments: ejercicio.exercise,
                              );
                            },
                            onEdit: () async {
                              final resultadoEditado = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExerciseConfigScreen(
                                    exercise: ejercicio.exercise,
                                    existingConfig: ejercicio,
                                  ),
                                ),
                              );

                              if (resultadoEditado != null &&
                                  resultadoEditado is ConfiguredExercise) {
                                setState(() {
                                  int index = listaEjerciciosConfigurados
                                      .indexWhere(
                                        (e) =>
                                            e.instanceId ==
                                            ejercicio.instanceId,
                                      );
                                  if (index != -1) {
                                    listaEjerciciosConfigurados[index] =
                                        resultadoEditado;
                                  }
                                });
                              }
                            },
                          );
                        }),

                      const SizedBox(height: 15),
                      _buildAddButton(),
                      const SizedBox(height: 25),

                      // --- SECCIÓN DE COMENTARIO GENERAL ---
                      _buildGeneralCommentSection(),

                      const SizedBox(height: 20),
                      _buildCreateSessionButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required ConfiguredExercise ejercicio,
    required VoidCallback onDelete,
    required VoidCallback onInfo,
    required VoidCallback onEdit,
  }) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ejercicio.exercise.thumbnailImageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.white10,
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ejercicio.exercise.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ejercicio.notes.isEmpty
                        ? "Sin comentario agregado."
                        : ejercicio.notes,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onInfo,
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.accentLila,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "COMENTARIOS DE LA RUTINA",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _comentarioGeneralController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Añade instrucciones generales para esta sesión...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.cardBg.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(15),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Crear Rutina",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSelectorCliente() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_outline, color: Colors.white70, size: 20),
          SizedBox(width: 10),
          Text(
            "Cliente: Alejandro Perez García",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTitulo() {
    return TextField(
      controller: _tituloController,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: "Título de la rutina",
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.dimmedColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Text(
        "No hay ejercicios. Pulsa el botón para añadir.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPurple,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _abrirBuscador,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        "Agregar nuevo ejercicio",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildCreateSessionButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.accentLila),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          // Aquí enviarías tanto listaEjerciciosConfigurados como _comentarioGeneralController.text
          Navigator.pop(context);
        },
        child: const Text(
          "GUARDAR RUTINA",
          style: TextStyle(
            color: AppColors.accentLila,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
