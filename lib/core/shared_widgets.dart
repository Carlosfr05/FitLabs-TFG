import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

/// Divisor discontinuo (línea de puntos horizontal).
class DashedDivider extends StatelessWidget {
  final Color color;
  final double dashWidth;
  final double height;
  final EdgeInsets padding;

  const DashedDivider({
    super.key,
    this.color = AppColors.dimmedColor,
    this.dashWidth = 8.0,
    this.height = 2.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 15),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Línea lateral curva usada en la lista de entrenamientos.
class CurvedSideLine extends StatelessWidget {
  final Color color;
  const CurvedSideLine({super.key, this.color = AppColors.dimmedColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.elliptical(4, 40)),
      ),
    );
  }
}

/// Divisor horizontal discontinuo fino para el timeline del calendario.
class TimeDivider extends StatelessWidget {
  final Color color;
  const TimeDivider({super.key, this.color = AppColors.cardBg});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        );
      },
    );
  }
}
