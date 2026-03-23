import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class ResumenDiaScreen extends StatefulWidget {
  const ResumenDiaScreen({super.key});

  @override
  State<ResumenDiaScreen> createState() => _ResumenDiaScreenState();
}

class _ResumenDiaScreenState extends State<ResumenDiaScreen> {
  // Índice 0 = Inicio (Esta pantalla)
  int _selectedIndex = 0;
  double surfaceRadius = 0.0;

  // Datos de ejemplo
  final List<Map<String, String>> upcomingWorkouts = [
    {
      "title": "Sesión cardio-fuerza 1:1",
      "time": "09:30 - 10:45",
      "subtitle": "Carlos Luis Ramos García",
    },
    {
      "title": "Sesión cardio - HIIT",
      "time": "11:00 - 11:30",
      "subtitle": "Jaime Castanedo Mateos",
    },
    {
      "title": "Sesión entrenamiento - Torso 1:2",
      "time": "12:00 - 13:00",
      "subtitle": "José Luis Sánchez González",
    },
    {
      "title": "Sesión entrenamiento - Piernas 1:1",
      "time": "13:10 - 14:15",
      "subtitle": "Coraima Medina Lechuga",
    },
    {
      "title": "Sesión Recuperación Hombros",
      "time": "16:00 - 16:30",
      "subtitle": "José Luis Reina Sánchez",
    },
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // Navegación basada en tus rutas del main.dart
    switch (index) {
      case 0:
        // Ya estamos en /resumen
        break;
      case 1:
        Navigator.pushNamed(context, '/clientes');
        break;
      case 2:
        Navigator.pushNamed(context, '/calendario');
        break;
      case 3:
        Navigator.pushNamed(context, '/mensajes');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- COLORES Y ESTILOS AJUSTADOS ---
    // NUEVO RADIO: Bordes más redondeados
    final double surfaceRadius = 0;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                _buildHeader(),
                const SizedBox(height: 30),

                // Resumen (Con nuevos estilos)
                _buildSummaryCard(surfaceRadius),
                const SizedBox(height: 30),

                // Grid Botones (Con nuevos estilos y altura)
                _buildActionButtonsGrid(surfaceRadius),
                const SizedBox(height: 30),

                // Título
                Text(
                  'Entrenamientos Próximos',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Lista
                _buildWorkoutList(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        color: AppColors.navBarBg,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, "Inicio"),
            _buildNavItem(1, Icons.people_outlined, "Clientes"),
            _buildNavItem(2, Icons.calendar_today, "Calendario"),
            _buildNavItem(
              3,
              Icons.mail,
              "Mensajes",
              badgeCount: 2,
              accentColor: AppColors.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image(
          image: AssetImage('assets/images/imagenPerfil.png'),
          width: 50,
          height: 50,
        ),
        const Text(
          'FitLabs',
          style: TextStyle(
            fontFamily: 'RubikVinyl',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '8',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            const Icon(Icons.settings, color: Colors.white, size: 28),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double radius) {
    return Container(
      padding: const EdgeInsets.all(20),
      // Aplicamos el nuevo color y radio
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del día',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _item('3', 'Sesiones Realizadas'),
              Container(
                height: 40,
                width: 1,
                color: AppColors.dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              _item('5', 'Sesiones Restantes'),
              Container(
                height: 40,
                width: 1,
                color: AppColors.dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              _item('2', 'Mensajes sin leer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.dimmedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsGrid(double radius) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _btn('Añadir nuevo\ncliente', Icons.person_add)),
            const SizedBox(width: 15),
            Expanded(
              child: _btn(
                'Crear nueva\nrutina',
                Icons.fitness_center,
                showPlus: true,
                onTap: () {
                  Navigator.pushNamed(context, '/crear-rutina');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _btn('Modificar rutina\nexistente', Icons.edit)),
            const SizedBox(width: 15),
            Expanded(
              child: _btn('Revisar pagos\nde clientes', Icons.monetization_on),
            ),
          ],
        ),
      ],
    );
  }

  Widget _btn(
    String label,
    IconData? icon, {
    bool showPlus = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(surfaceRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        height: 65,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(surfaceRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (icon != null) Icon(icon, color: Colors.white70, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: upcomingWorkouts.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: DashedDivider(),
      ),
      itemBuilder: (context, index) {
        final w = upcomingWorkouts[index];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CurvedSideLine(),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      w['title']!,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      w['time']!,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      w['subtitle']!,
                      style: TextStyle(
                        color: AppColors.subTextColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    int badgeCount = 0,
    Color? accentColor,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.textColor
                    : AppColors.subTextColor,
                size: 28,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -5,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.navBarBg, width: 1.5),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textColor : AppColors.subTextColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS PERSONALIZADOS ---
class CurvedSideLine extends StatelessWidget {
  const CurvedSideLine({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: AppColors.dimmedColor,
        borderRadius: const BorderRadius.all(Radius.elliptical(4, 40)),
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 10.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(
              dashCount,
              (_) => SizedBox(
                width: dashWidth,
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.dimmedColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
