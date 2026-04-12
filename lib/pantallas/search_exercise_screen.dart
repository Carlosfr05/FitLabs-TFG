import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/data/exercise_search_repository.dart';
import 'dart:async';

import 'package:pantallas_fitlabs/data/exercise_search_response.dart';
import 'package:pantallas_fitlabs/pantallas/exercise_config_screen.dart';
import 'package:pantallas_fitlabs/pantallas/exercise_detail_screen.dart';
import 'package:pantallas_fitlabs/data/history_service.dart'; 

class SearchExerciseScreen extends StatefulWidget {
  const SearchExerciseScreen({super.key});

  @override
  State<SearchExerciseScreen> createState() => _SearchExerciseScreenState();
}

class _SearchExerciseScreenState extends State<SearchExerciseScreen> {
  List<String> nombresRecientes = [];
  ExerciseSearchRepository exerciseSearchRepository = ExerciseSearchRepository();
  final TextEditingController _searchController = TextEditingController(); 
  int _currentPage = 1;
  Timer? _debounce;
  Future<ExerciseSearchResponse?>? llamadaApi;
  bool isTextEmpty = true;
  String queryString = "";
  int maxPages = 1;

  @override
  void initState() {
    super.initState();
    _cargarRecientes();
  }

  void _cargarRecientes() async {
    final lista = await HistoryService.obtenerHistorial();
    setState(() {
      nombresRecientes = lista;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        child: Icon(Icons.arrow_back, color: AppColors.textColor),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Text(
                    'Buscar Ejercicio',
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

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: _searchController,
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
                    prefixIcon: Icon(Icons.search, color: AppColors.textColor),
                  ),
                  onChanged: (query) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      setState(() {
                        isTextEmpty = query.isEmpty;
                        queryString = query;
                        _currentPage = 1;
                        if (!isTextEmpty) {
                          llamadaApi = exerciseSearchRepository.searchExercises(queryString, _currentPage);
                        }
                      });
                    });
                  },
                ),
              ),
            ),

            // LISTADO
            Expanded(child: bodyList(isTextEmpty)),
          ],
        ),
      ),
    );
  }

  Widget bodyList(bool isTextEmpty) {
    if (isTextEmpty) {
      return mostrarVacio();
    }

    return FutureBuilder<ExerciseSearchResponse?>(
      future: llamadaApi,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.dimmedColor));
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
        } else if (snapshot.hasData && snapshot.data != null) {
          var exerciseResponse = snapshot.data!;
          maxPages = exerciseResponse.totalPages;
          var exerciseList = exerciseResponse.exercisesList;

          return Column(
            children: [
              _buildPaginator(maxPages),
              Expanded(
                child: ListView.builder(
                  itemCount: exerciseList.length,
                  itemBuilder: (context, index) => itemExercise(exerciseList[index]),
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget mostrarVacio() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            nombresRecientes.isEmpty ? "EMPIEZA A BUSCAR" : "BÚSQUEDAS RECIENTES",
            style: TextStyle(
              color: AppColors.dimmedColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          if (nombresRecientes.isEmpty)
            Text(
              "Busca por nombre o músculo para mostrar ejercicios",
              style: TextStyle(color: AppColors.hintText, fontSize: 15),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: nombresRecientes.map((nombre) {
                return GestureDetector(
                  onTap: () {
                    // Acción al pulsar un reciente: rellenar y buscar
                    _searchController.text = nombre;
                    setState(() {
                      isTextEmpty = false;
                      queryString = nombre;
                      _currentPage = 1;
                      llamadaApi = exerciseSearchRepository.searchExercises(queryString, _currentPage);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.dimmedColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 14, color: AppColors.dimmedColor),
                        const SizedBox(width: 8),
                        Text(nombre, style: TextStyle(color: AppColors.textColor, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget itemExercise(Exercise item) {
    return GestureDetector(
      onTap: () async {
        // --- GUARDADO INMEDIATO AL PULSAR ---
        await HistoryService.guardarEjercicio(item.name);
        _cargarRecientes(); // Refrescamos la lista interna

        final configurado = await Navigator.push<ConfiguredExercise>(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseConfigScreen(exercise: item),
          ),
        );

        if (!mounted) return;

        // Aquí ya no guardamos, solo hacemos el pop si procede
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
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.dimmedColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.primaryMuscles[0],
                        style: TextStyle(color: AppColors.dimmedColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.info_outline, color: AppColors.cardBorder, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise: item)),
                      );
                    },
                  ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _currentPage > 1 ? AppColors.textColor : Colors.grey),
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                    llamadaApi = exerciseSearchRepository.searchExercises(queryString, _currentPage);
                  });
                }
              : null,
        ),
        Text("Página $_currentPage de $totalPages", style: TextStyle(color: AppColors.textColor)),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: _currentPage < totalPages ? AppColors.textColor : Colors.grey),
          onPressed: _currentPage < totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                    llamadaApi = exerciseSearchRepository.searchExercises(queryString, _currentPage);
                  });
                }
              : null,
        ),
      ],
    );
  }
}