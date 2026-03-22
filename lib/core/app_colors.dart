import 'package:flutter/material.dart';

class AppColors {
  //Gradient del background
  static Gradient? bgGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF352B55),Color(0xFF2A223E), Color(0xFF1E1A2B)],
    stops: [0.0, 0.3, 1.0],
  );
  // --- COLORES --- //
  static const Color accentLila = Color(0xFF9F97E6);
  static const Color textColor = Colors.white;
  static const Color dimmedColor = Color(0xFFD5D0FF);
  static const Color dividerColor = Colors.white24;
  static const Color cardBg = Color(0xFF655EA4);
  static const Color cardBorder = Color(0xFFADA4FF);
  static const Color bgTop = Color(0xFF352B55);
  static const Color bgBottom = Color(0xFF1E1A2B);
  static const Color cardBg2 = Color.fromARGB(174, 106, 98, 150); 
  static const Color accentPurple = Color(0xFF6C63FF); 
}
