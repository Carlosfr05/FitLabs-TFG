import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/data/exercise_search_repository.dart';
import 'dart:async';

import 'package:pantallas_fitlabs/data/exercise_search_response.dart';
import 'package:pantallas_fitlabs/pantallas/exercise_config_screen.dart';
import 'package:pantallas_fitlabs/pantallas/exercise_detail_screen.dart';

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
                      child: TextField(
                        cursorColor: AppColors.dimmedColor,
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
            return Text(
              "Estado: ${snapshot.connectionState}, Datos: ${snapshot.data}",
              style: TextStyle(color: Colors.white),
            );
          }
        },
      );

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Container mostrarVacio() {
    return Container(
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
    );
  }

  Widget itemExercise(Exercise item) {
    return GestureDetector(
      onTap: () async {
        final configurado = await Navigator.push<ConfiguredExercise>(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseConfigScreen(exercise: item),
          ),
        );

        //Verificamos si el widget sigue en pantalla
        if (!mounted) return;

        //Si sigue vivo y hay datos, hacemos el pop
        if (configurado != null) {
          Navigator.pop(context, configurado);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 120,
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
            // 1. Imagen (Sin cambios)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  color: Colors.white.withOpacity(0.05),
                  child: Image.network(
                    item.thumbnailImageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    // ... tus builders de carga y error ...
                  ),
                ),
              ),
            ),

            // 2. Información Central (Sin cambios)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dimmedColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.primaryMuscles[0],
                        style: TextStyle(
                          color: AppColors.dimmedColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.handyman_outlined,
                          size: 14,
                          color: AppColors.hintText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.equipment ?? "unknown",
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

            // 3. LATERAL DERECHO: Botón Info + Flecha
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment
                    .spaceEvenly, // Distribuye info arriba y flecha abajo
                children: [
                  // BOTÓN DE INFO
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: AppColors.cardBorder,
                      size: 22,
                    ),
                    onPressed: () {
                      // AQUÍ LLEVAS A LA PANTALLA DE DETALLES TÉCNICOS
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ExerciseDetailScreen(exercise: item),
                        ),
                      );
                    },
                  ),
                  // FLECHA INDICADORA
                  Icon(Icons.chevron_right, color: AppColors.accentLila),
                ],
              ),
            ),
          ],
        ),
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
