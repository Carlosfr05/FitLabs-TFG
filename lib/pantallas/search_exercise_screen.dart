import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class SearchExerciseScreen extends StatefulWidget {
  const SearchExerciseScreen({super.key});

  @override
  State<SearchExerciseScreen> createState() => _SearchExerciseScreenState();
}

class _SearchExerciseScreenState extends State<SearchExerciseScreen> {
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
                      child: Icon(Icons.arrow_back, color: AppColors.textColor),
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
                child: TextField(
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
                    prefixIcon: Icon(Icons.search, color: AppColors.textColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 100,
                      vertical: 0, // Esto quita el espacio fantasma
                    ),
                  ),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
