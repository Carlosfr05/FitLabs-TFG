import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class CrearRutinaScreen extends StatefulWidget {
  const CrearRutinaScreen({super.key});

  @override
  State<CrearRutinaScreen> createState() => _CrearRutinaScreenState();
}

class _CrearRutinaScreenState extends State<CrearRutinaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset:
          false, // Evita que el teclado rompa el diseño al abrirse
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER (Fijo)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
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
                    Expanded(
                      child: Center(
                        child: Text(
                          "Crear Rutina",
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Equilibrio visual flecha
                  ],
                ),
              ),

              // CONTENIDO SCROLLABLE
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 15),

                      // --- SELECTOR DE CLIENTE ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Sans',
                                  ), // Asegura fuente base
                                  children: [
                                    TextSpan(
                                      text: "Cliente seleccionado: ",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextSpan(
                                      text: "Alejandro Perez García",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.more_vert,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // --- INPUT TÍTULO (CORREGIDO) ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Título:",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          TextField(
                            controller: TextEditingController(
                              text: "Sesión entrenamiento PUSH - hipertrofia",
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                            cursorColor: Colors.white,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                              ), // Texto pegado a la línea
                              // Línea inferior blanca (estado normal)
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.dimmedColor,
                                  width: 1.0,
                                ),
                              ),
                              // Línea inferior blanca más gruesa (foco)
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // --- LISTA DE EJERCICIOS ---

                      // Ejercicio 1
                      _buildExerciseCard(
                        title: "Press banca plano mancuernas",
                        series: "3",
                        reps: "8 - 10",
                        kg: "25",
                        // iconPlaceholder: Icons.fitness_center,
                        // CAMBIA ESTO por tu imagen real cuando la tengas:
                        imageAsset: "assets/images/bench_press.png",
                      ),

                      // Ejercicio 2
                      _buildExerciseCard(
                        title: "Peck deck en máquina",
                        series: "4",
                        reps: "10 - 12",
                        kg: "45",
                        imageAsset: "assets/images/peck_deck.png",
                      ),

                      // Ejercicio 3
                      _buildExerciseCard(
                        title: "Extensión triceps en polea",
                        series: "3",
                        reps: "10 - 12",
                        kg: "35",
                        imageAsset: "assets/images/triceps.png",
                      ),

                      const SizedBox(height: 25),

                      // --- BOTÓN AGREGAR EJERCICIO ---
                      Material(
                        color: AppColors.accentPurple,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () {
                            // Acción agregar
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Agregar nuevo ejercicio",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.add, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- BOTÓN CREAR SESIÓN ---
                      Container(
                        width: 180,
                        height: 45,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.dimmedColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: () {
                            // Acción guardar
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Crear Sesión",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
      ),
    );
  }

  // --- WIDGET TARJETA DE EJERCICIO ---
  Widget _buildExerciseCard({
    required String title,
    required String series,
    required String reps,
    required String kg,
    String? imageAsset, // Ruta de imagen opcional
    IconData iconPlaceholder = Icons.image, // Icono por defecto
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. FOTO / ICONO
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            // Si tienes imágenes, usa Image.asset. Si no, usa el icono.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageAsset != null
                  // ? Image.asset(imageAsset, fit: BoxFit.cover) // DESCOMENTAR CUANDO TENGAS IMAGENES
                  ? Icon(
                      Icons.fitness_center,
                      color: Colors.black87,
                      size: 30,
                    ) // Placeholder temporal
                  : Icon(iconPlaceholder, color: Colors.black87, size: 30),
            ),
          ),
          const SizedBox(width: 15),

          // 2. INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + Menú
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats (Series - Reps - Kg)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Series", series),
                    _buildStatItem("Reps", reps),
                    _buildStatItem("kg", kg),
                    const SizedBox(width: 5),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
