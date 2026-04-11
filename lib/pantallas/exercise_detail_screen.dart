import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  // Controlador para el carrusel de imágenes
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _pageController.dispose(); // Siempre es buena práctica limpiar los controladores
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
            // --- 1. TU CABECERA (App Bar Custom) ---
            Padding(
              padding: const EdgeInsets.only(
                top: 50, // Un poco más de margen superior para el notch del móvil
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
                        onTap: () {
                          Navigator.pop(context);
                        },
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

            // --- 2. CONTENIDO DESLIZABLE ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Título del Ejercicio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.exercise.name, // Usamos widget.exercise por ser StatefulWidget
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // B. El famoso Carrusel (PageView)
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.exercise.allImageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                color: Colors.white, // Fondo blanco por si la imagen tiene transparencias
                                child: Image.network(
                                  widget.exercise.allImageUrls[index],
                                  fit: BoxFit.contain, // Contain para que se vea el ejercicio entero
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // C. Etiquetas (Tags) de nivel y equipamiento
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildChip(widget.exercise.level.toUpperCase(), Icons.leaderboard),
                          _buildChip(widget.exercise.equipment ?? 'BODY ONLY', Icons.fitness_center),
                          _buildChip(widget.exercise.category, Icons.category),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // D. Músculos Implicados
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
                            widget.exercise.primaryMuscles.join(', ').toUpperCase(),
                            style: TextStyle(color: AppColors.textColor.withOpacity(0.7), fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // E. Instrucciones
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
                          // Generamos los pasos de las instrucciones
                          ...widget.exercise.instructions.map((paso) {
                            int index = widget.exercise.instructions.indexOf(paso) + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                        color: AppColors.textColor.withOpacity(0.8),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40), // Espacio extra al final para que respire
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para crear las "píldoras" (chips) de información
  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
