import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/data/translator_manager.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  // Variables de estado
  bool _isTranslating = true;
  String _translatedMuscles = "Traduciendo músculos..."; // Texto inicial
  List<String> _translatedInstructions = [
    "Traduciendo instrucciones...",
  ]; // Texto inicial

  @override
  void initState() {
    super.initState();
    // Ya no copiamos los datos en inglés al principio para que no se vean
    _traducirDatos();
  }

  Future<void> _traducirDatos() async {
    try {
      // Traducir músculos
      String textoMusculos = widget.exercise.primaryMuscles.join(', ');
      String musculosListos = await TranslatorManager.traducir(textoMusculos);

      // Traducir instrucciones
      List<String> instruccionesListas = [];
      for (String paso in widget.exercise.instructions) {
        String pasoTraducido = await TranslatorManager.traducir(paso);
        instruccionesListas.add(pasoTraducido);
      }

      if (mounted) {
        setState(() {
          _translatedMuscles = musculosListos.toUpperCase();
          _translatedInstructions = instruccionesListas;
          _isTranslating = false;
        });
      }
    } catch (e) {
      debugPrint("Error al traducir: $e");
      if (mounted) {
        setState(() {
          // Si falla, aquí sí ponemos el inglés como respaldo
          _translatedMuscles = widget.exercise.primaryMuscles
              .join(', ')
              .toUpperCase();
          _translatedInstructions = widget.exercise.instructions;
          _isTranslating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        height: double.infinity,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. CABECERA ---
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.textColor,
                        ),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Text(
                    'Configurar Ejercicio',
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),

            // --- 2. CONTENIDO ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título (Este se queda en inglés por tu petición)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.exercise.name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carrusel
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.exercise.allImageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                color: Colors.white,
                                child: Image.network(
                                  widget.exercise.allImageUrls[index],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Chips (Nivel, Equipo...)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildChip(
                            widget.exercise.level.toUpperCase(),
                            Icons.leaderboard,
                          ),
                          _buildChip(
                            widget.exercise.equipment ?? 'BODY ONLY',
                            Icons.fitness_center,
                          ),
                          _buildChip(widget.exercise.category, Icons.category),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Músculos (Variable de traducción)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Músculos Principales:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _translatedMuscles,
                            style: TextStyle(
                              color: _isTranslating
                                  ? AppColors.textColor.withValues(alpha: 0.4)
                                  : AppColors.textColor.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontStyle: _isTranslating
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Instrucciones (Lista de traducción)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instrucciones:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ..._translatedInstructions.asMap().entries.map((
                            entry,
                          ) {
                            int index = entry.key + 1;
                            String paso = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Solo mostramos el número si no estamos cargando
                                  if (!_isTranslating)
                                    Text(
                                      '$index. ',
                                      style: TextStyle(
                                        color: AppColors.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      paso,
                                      style: TextStyle(
                                        color: _isTranslating
                                            ? AppColors.textColor.withValues(
                                                alpha: 0.4,
                                              )
                                            : AppColors.textColor.withValues(
                                                alpha: 0.8,
                                              ),
                                        height: 1.5,
                                        fontStyle: _isTranslating
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
