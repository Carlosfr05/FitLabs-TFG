import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
export 'package:pantallas_fitlabs/core/app_colors.dart';

/// Fondo con imagen PNG pre-renderizada con dithering.
/// Se estira a cualquier tamaño de pantalla sin banding.
class AppBackground extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;

  const AppBackground({
    super.key,
    required this.child,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bg_gradient.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
