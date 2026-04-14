import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final items = _itemsForRole();

    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        color: AppColors.navBarBg,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () {
                if (index == currentIndex) return;
                Navigator.pushReplacementNamed(context, item.route);
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
