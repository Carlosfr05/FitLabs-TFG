import 'package:flutter/material.dart';
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
class AppBottomNavBar extends StatelessWidget {
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
    const minSwipeVelocity = 250.0;

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
    final beginOffset = targetIndex > currentIndex
        ? const Offset(1, 0)
        : const Offset(-1, 0);

    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _screenForRoute(route),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curved);
        final fade = Tween<double>(begin: 0.94, end: 1).animate(curved);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
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
  Widget build(BuildContext context) {
    final items = _itemsForRole();

    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        color: const Color.fromARGB(255, 72, 68, 114),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () {
                navigateToIndex(context, currentIndex, index);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? Colors.white
                        : AppColors.navIconUnselected,
                    size: 28,
                  ),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
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
