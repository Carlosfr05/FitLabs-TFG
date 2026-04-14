import 'package:flutter/material.dart';

class AppColors {
  // Gradientes (solo para uso legacy, preferir AppBackground)
  static Gradient? bgGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF352B55), Color(0xFF151220)],
  );

  static Gradient? loginGradient = const LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF3E2B68), Color(0xFF181428)],
  );
  // --- COLORES --- //
  static const Color accentLila = Color(0xFF9F97E6);
  static const Color textColor = Colors.white;
  static const Color dimmedColor = Color(0xFFD5D0FF);
  static const Color dividerColor = Colors.white24;
  static const Color cardBg = Color(0xFF655EA4);
  static const Color cardBorder = Color(0xFFADA4FF);
  static const Color bgTop = Color(0xFF352B55);
  static const Color bgBottom = Color(0xFF151220);
  static const Color cardBg2 = Color.fromARGB(174, 106, 98, 150);
  static const Color accentPurple = Color(0xFF6C63FF);
  static const Color cardSummaryBg = Color(0xFF3E3666);
  static const Color cardGraphBg = Color(0xFF2B253F);
  static const Color hintText = Color(0x99FFFFFF);
  static const Color searchBarBg = Color(0xFF463C6E);
  static const Color chatCardBg = Color(0xFF2E2744);
  static const Color navBarBg = Color(0xFF413E60);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color avatarBg = Color(0xFFE0E0E0);
  static const Color fabBg = Color(0xFF6C639F);
  static const Color surfaceColor = Color(0xFF776DAE);
  static const Color surfaceColor2 = Color(0xFF4B4584);
  static const Color subTextColor = Colors.white60;
  static const Color navIconUnselected = Color(0xFFAFA8D5);
  static const Color secondarySurface = Color(0xFF5A5290);
}
