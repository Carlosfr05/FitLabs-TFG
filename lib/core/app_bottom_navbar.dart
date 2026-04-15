import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/pantallas/calendario_screen.dart';
import 'package:pantallas_fitlabs/pantallas/cliente_home_screen.dart';
import 'package:pantallas_fitlabs/pantallas/mensajes_screen.dart';
import 'package:pantallas_fitlabs/pantallas/mis_clientes.dart';
import 'package:pantallas_fitlabs/pantallas/perfil_screen.dart';
import 'package:pantallas_fitlabs/pantallas/resumen_dia.dart';

/// Navbar inferior compartido por todas las pantallas.
/// Muestra items diferentes según el rol del usuario.
class AppBottomNavBar extends StatefulWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  static List<_NavItem> _itemsForRole() {
    if (SessionService.isEntrenador) {
      return [
        _NavItem(icon: Icons.home_filled, label: 'Inicio', route: '/resumen'),
        _NavItem(
          icon: Icons.people_outlined,
          label: 'Clientes',
          route: '/clientes',
        ),
        _NavItem(
          icon: Icons.calendar_today,
          label: 'Calendario',
          route: '/calendario',
        ),
        _NavItem(icon: Icons.mail, label: 'Mensajes', route: '/mensajes'),
        _NavItem(icon: Icons.person_outline, label: 'Perfil', route: '/perfil'),
      ];
    } else {
      return [
        _NavItem(
          icon: Icons.home_filled,
          label: 'Mi Rutina',
          route: '/cliente-home',
        ),
        _NavItem(
          icon: Icons.calendar_today,
          label: 'Calendario',
          route: '/calendario',
        ),
        _NavItem(icon: Icons.mail, label: 'Mensajes', route: '/mensajes'),
        _NavItem(icon: Icons.person_outline, label: 'Perfil', route: '/perfil'),
      ];
    }
  }

  static void navigateToIndex(
    BuildContext context,
    int currentIndex,
    int targetIndex,
  ) {
    final items = _itemsForRole();
    if (targetIndex < 0 || targetIndex >= items.length) return;
    if (targetIndex == currentIndex) return;

    final target = items[targetIndex];
    Navigator.of(
      context,
    ).pushReplacement(_buildTabRoute(target.route, currentIndex, targetIndex));
  }

  static void handleHorizontalSwipe(
    BuildContext context,
    int currentIndex,
    DragEndDetails details,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    const minSwipeVelocity = 200.0;

    if (velocity <= -minSwipeVelocity) {
      navigateToIndex(context, currentIndex, currentIndex + 1);
    } else if (velocity >= minSwipeVelocity) {
      navigateToIndex(context, currentIndex, currentIndex - 1);
    }
  }

  static PageRouteBuilder<void> _buildTabRoute(
    String route,
    int currentIndex,
    int targetIndex,
  ) {
    final goingRight = targetIndex > currentIndex;
    final beginOffset = goingRight ? const Offset(1, 0) : const Offset(-1, 0);
    final exitOffset = goingRight
        ? const Offset(-0.3, 0)
        : const Offset(0.3, 0);

    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _screenForRoute(route),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Curva con rebote suave para la pantalla entrante
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
        );
        // Curva para la pantalla saliente
        final exitCurved = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOutCubic,
        );

        final slideIn = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curved);

        final slideOut = Tween<Offset>(
          begin: Offset.zero,
          end: exitOffset,
        ).animate(exitCurved);

        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        final scaleIn = Tween<double>(begin: 0.96, end: 1.0).animate(curved);

        return SlideTransition(
          position: slideOut,
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: ScaleTransition(scale: scaleIn, child: child),
            ),
          ),
        );
      },
    );
  }

  static Widget _screenForRoute(String route) {
    switch (route) {
      case '/resumen':
        return const ResumenDiaScreen();
      case '/clientes':
        return const MisClientesScreen();
      case '/calendario':
        return const CalendarioScreen();
      case '/mensajes':
        return const MensajesScreen();
      case '/cliente-home':
        return const ClienteHomeScreen();
      case '/perfil':
        return const PerfilScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _tapControllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _glowAnims;

  @override
  void initState() {
    super.initState();
    final items = AppBottomNavBar._itemsForRole();
    _tapControllers = List.generate(items.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
    _scaleAnims = _tapControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack));
    }).toList();
    _glowAnims = _tapControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _tapControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    _tapControllers[index].forward(from: 0);
    // Pequeño delay para que la animación se vea antes de navegar
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        AppBottomNavBar.navigateToIndex(context, widget.currentIndex, index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = AppBottomNavBar._itemsForRole();

    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 72, 68, 114),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = widget.currentIndex == index;
            return GestureDetector(
              onTap: () => _onTap(index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / items.length,
                child: AnimatedBuilder(
                  animation: _tapControllers[index],
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: _scaleAnims[index].value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow detrás del icono
                              if (_glowAnims[index].value > 0)
                                Container(
                                  width: 40 + 10 * _glowAnims[index].value,
                                  height: 40 + 10 * _glowAnims[index].value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentLila.withValues(
                                      alpha: 0.25 * _glowAnims[index].value,
                                    ),
                                  ),
                                ),
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.navIconUnselected,
                                size: 26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Indicador activo
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? 18 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isSelected
                                ? AppColors.accentLila
                                : Colors.transparent,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
