import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/data/exercise_search_repository.dart';
import 'dart:async';

import 'package:pantallas_fitlabs/data/exercise_search_response.dart';

class SearchExerciseScreen extends StatefulWidget {
  const SearchExerciseScreen({super.key});

  @override
  State<SearchExerciseScreen> createState() => _SearchExerciseScreenState();
}

class _SearchExerciseScreenState extends State<SearchExerciseScreen> {
  ExerciseSearchRepository exerciseSearchRepository =
      ExerciseSearchRepository();
  int _currentPage = 1;
  Timer? _debounce;
  Future<ExerciseSearchResponse?>? llamadaApi;
  bool isTextEmpty = true;
  String queryString = "";
  int maxPages = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 30,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Row(
                children: [
                  // 1. Lado izquierdo con el icono
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

                  // 2. Texto en el centro absoluto
                  Text(
                    'Buscar Ejercicio',
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 3. Lado derecho vacío como "contrapeso"
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(cursorColor: AppColors.dimmedColor,
                      style: TextStyle(color: AppColors.textColor),
                        decoration: InputDecoration(
                          hintText: "Buscar Ejercicio",
                          hintStyle: TextStyle(color: AppColors.hintText),
                          filled: true,
                          fillColor: AppColors.searchBarBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                          hintFadeDuration: Duration(milliseconds: 200),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textColor,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 0, // Esto quita el espacio fantasma
                          ),
                        ),
                        onChanged: (query) {
                          _debounce?.cancel();
                          _debounce = Timer(Duration(milliseconds: 300), () {
                            setState(() {
                              isTextEmpty = query.isEmpty;
                              queryString = query;
                              _currentPage = 1;
                              llamadaApi = exerciseSearchRepository
                                  .searchExercises(queryString, _currentPage);
                            });
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(child: bodyList(isTextEmpty)),
          ],
        ),
      ),
    );
  }

  FutureBuilder<ExerciseSearchResponse?> bodyList(bool isTextEmpty) =>
      FutureBuilder(
        future: llamadaApi,
        builder: (context, snapshot) {
          if (isTextEmpty) {
            return mostrarVacio();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.dimmedColor),
              ),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            var exerciseResponse = snapshot.data!;
            maxPages = exerciseResponse.totalPages;
            var exerciseList = exerciseResponse.exercisesList;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildPaginator(maxPages),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: exerciseList.length,
                    itemBuilder: (context, index) {
                      return itemExercise(exerciseList[index]);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Text("error");
          }
        },
      );

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Expanded mostrarVacio() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(top: 15),
        decoration: BoxDecoration(color: AppColors.bgBottom),
        child: Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: Text(
            "Busca por nombre o musculo para mostar ejercicios",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

Widget itemExercise(Exercise item) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    height: 120, // Un poco más compacto y elegante
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // 1. Imagen a la izquierda
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              color: Colors.white.withOpacity(0.05), // Fondo sutil por si el GIF es transparente
              child: Image.network(
                item.gifUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.textColor),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.white,
                  child: const Icon(Icons.fitness_center, color: Colors.black),
                ),
              ),
            ),
          ),
        ),

        // 2. Información a la derecha
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nombre del ejercicio (Capitalizado)
                Text(
                  item.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Etiqueta del músculo (Target)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dimmedColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.targetMuscles[0], // El músculo principal
                    style: TextStyle(
                      color: AppColors.dimmedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Equipo (Equipment) con icono pequeño
                Row(
                  children: [
                    Icon(Icons.handyman_outlined, size: 14, color: AppColors.hintText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.equipments[0],
                        style: TextStyle(
                          color: AppColors.hintText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Flechita indicadora al final
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(Icons.chevron_right, color: AppColors.hintText.withOpacity(0.5)),
        ),
      ],
    ),
  );
}

  Widget _buildPaginator(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón Anterior
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: _currentPage > 1 ? AppColors.textColor : Colors.grey,
            ),
            onPressed: _currentPage > 1
                ? () {
                    _currentPage--;
                    setState(() {
                      llamadaApi = exerciseSearchRepository.searchExercises(
                        queryString,
                        _currentPage,
                      );
                    });
                  }
                : null,
          ),

          // Número de página
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Página $_currentPage de $totalPages",
              style: TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Botón Siguiente
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: AppColors.textColor),
            onPressed: _currentPage < maxPages
                ? () {
                    _currentPage++;
                    setState(() {
                      llamadaApi = exerciseSearchRepository.searchExercises(
                        queryString,
                        _currentPage,
                      );
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
