import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/pantallas/resumen_dia.dart';
import 'package:pantallas_fitlabs/pantallas/mis_clientes.dart';
import 'package:pantallas_fitlabs/pantallas/calendario_screen.dart';
import 'package:pantallas_fitlabs/pantallas/mensajes_screen.dart';
import 'package:pantallas_fitlabs/pantallas/perfil_screen.dart';
import 'package:pantallas_fitlabs/pantallas/cliente_home_screen.dart';

/// Shell principal que contiene un PageView para las pestañas
/// y un navbar inferior persistente (no se destruye al cambiar de pestaña).
class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  /// Permite a cualquier pantalla hija cambiar de pestaña sin reconstruir el shell.
  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_HomeShellState>()?._animateToPage(index);
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex;
  late PageController _pageController;
  late final List<_NavItem> _items;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    if (SessionService.isEntrenador) {
      _items = const [
        _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_filled,
          label: 'Inicio',
        ),
        _NavItem(
          icon: Icons.people_outlined,
          activeIcon: Icons.people,
          label: 'Clientes',
        ),
        _NavItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_month,
          label: 'Calendario',
        ),
        _NavItem(
          icon: Icons.mail_outlined,
          activeIcon: Icons.mail,
          label: 'Mensajes',
        ),
        _NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Perfil',
        ),
      ];
      _screens = const [
        ResumenDiaScreen(),
        MisClientesScreen(),
        CalendarioScreen(),
        MensajesScreen(),
        PerfilScreen(),
      ];
    } else {
      _items = const [
        _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_filled,
          label: 'Mi Rutina',
        ),
        _NavItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_month,
          label: 'Calendario',
        ),
        _NavItem(
          icon: Icons.mail_outlined,
          activeIcon: Icons.mail,
          label: 'Mensajes',
        ),
        _NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Perfil',
        ),
      ];
      _screens = const [
        ClienteHomeScreen(),
        CalendarioScreen(),
        MensajesScreen(),
        PerfilScreen(),
      ];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int index) {
    if (index == _currentIndex || index < 0 || index >= _items.length) return;
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
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
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, _buildNavItem),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _animateToPage(index),
        splashColor: AppColors.accentLila.withValues(alpha: 0.15),
        highlightColor: AppColors.accentLila.withValues(alpha: 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? Colors.white : AppColors.navIconUnselected,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 16 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: AppColors.accentLila,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
