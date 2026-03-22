import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  int _selectedIndex = 2; // Índice 2 = Calendario

  // --- NAVEGACIÓN ---
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/resumen'); // Ajusta a tu ruta 'home'
        break;
      case 1:
        Navigator.pushNamed(context, '/clientes');
        break;
      case 2:
        break; // Ya estamos aquí
      case 3:
        Navigator.pushNamed(context, '/mensajes');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.bgGradient
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Título
              Text(
                'Calendario',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // --- CALENDARIO (Parte Superior Fija) ---
              _buildCalendarWidget(),

              SizedBox(height: 20),

              // Divisor
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: DashedDivider(),
              ),

              // --- TIMELINE (Parte Inferior Scrollable) ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 20, bottom: 100),
                  children: [
                    _buildTimeSlot("08 : 00", null),
                    _buildTimeSlot("09 : 00", null),
                    _buildTimeSlot(
                      "10 : 00",
                      _buildEventCard(
                        "Sesión cardio-fuerza 1:1",
                        "Carlos Luis Ramos García",
                      ),
                    ),
                    _buildTimeSlot(
                      "11 : 00",
                      _buildEventCard(
                        "Sesión cardio - HIIT",
                        "Jaime Castanedo Mateos",
                      ),
                    ),
                    _buildTimeSlot(
                      "12 : 00",
                      _buildEventCard(
                        "Sesión entrenamiento - Torso 1:2",
                        "José Luis Sánchez González",
                      ),
                    ),
                    _buildTimeSlot(
                      "13 : 00",
                      _buildEventCard(
                        "Sesión entrenamiento - Piernas 1:1",
                        "Coraima Medina Lechuga",
                      ),
                    ),
                    _buildTimeSlot("14 : 00", null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGETS DEL CALENDARIO (Corregido con GridView)
  // --------------------------------------------------------------------------

  Widget _buildCalendarWidget() {
    final List<String> weekDays = [
      "lun",
      "mar",
      "mie",
      "jue",
      "vie",
      "sab",
      "dom",
    ];

    // Datos simulados para Diciembre 2025 (Empieza en Lunes 1)
    final List<Map<String, dynamic>> days = [
      // Semana 1
      {"day": "1", "current": true},
      {"day": "2", "current": true},
      {"day": "3", "current": true},
      {"day": "4", "current": true},
      {"day": "5", "current": true},
      {"day": "6", "current": true},
      {"day": "7", "current": true},
      // Semana 2
      {"day": "8", "current": true}, {"day": "9", "current": true},
      {"day": "10", "current": true, "selected": true}, // Círculo lila
      {"day": "11", "current": true},
      {"day": "12", "current": true},
      {"day": "13", "current": true},
      {"day": "14", "current": true},
      // Semana 3
      {"day": "15", "current": true},
      {"day": "16", "current": true},
      {"day": "17", "current": true},
      {"day": "18", "current": true},
      {"day": "19", "current": true},
      {"day": "20", "current": true},
      {"day": "21", "current": true},
      // Semana 4
      {"day": "22", "current": true},
      {"day": "23", "current": true},
      {"day": "24", "current": true},
      {"day": "25", "current": true},
      {"day": "26", "current": true},
      {"day": "27", "current": true},
      {"day": "28", "current": true},
      // Semana 5 (Final mes + Inicio siguiente gris)
      {"day": "29", "current": true},
      {"day": "30", "current": true},
      {"day": "31", "current": true},
      {"day": "1", "current": false},
      {"day": "2", "current": false},
      {"day": "3", "current": false},
      {"day": "4", "current": false},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Selector de Mes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back_ios, color: AppColors.dimmedColor, size: 14),
              const SizedBox(width: 15),
              const Text(
                "Diciembre 2025",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 15),
              Icon(Icons.arrow_forward_ios, color: AppColors.dimmedColor, size: 14),
            ],
          ),
          const SizedBox(height: 20),

          // Cabecera días semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),

          // Grilla días (Fix: GridView con 7 columnas exactas)
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // <--- CLAVE: 7 días por semana
              mainAxisSpacing: 5,
              crossAxisSpacing: 0,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, index) {
              final dayData = days[index];
              return Center(
                child: _buildDayCell(
                  dayData["day"],
                  isCurrentMonth: dayData["current"],
                  isSelected: dayData["selected"] ?? false,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    String day, {
    bool isCurrentMonth = true,
    bool isSelected = false,
  }) {
    double size = 35;
    return Container(
      width: size,
      height: size,
      decoration: isSelected
          ? BoxDecoration(
              color: AppColors.accentLila.withOpacity(0.8),
              shape: BoxShape.circle,
            )
          : null,
      alignment: Alignment.center,
      child: Text(
        day,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isCurrentMonth ? Colors.white : AppColors.dimmedColor),
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGETS DEL TIMELINE
  // --------------------------------------------------------------------------

  Widget _buildTimeSlot(String time, Widget? content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(color: AppColors.textColor, fontSize: 12)),
                const SizedBox(height: 5),
                Container(width: 15, height: 1, color: AppColors.dimmedColor),
              ],
            ),
          ),

          // Contenido + Línea fondo
          Expanded(
            child: Stack(
              children: [
                // Línea discontinua detrás
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TimeDivider(color: AppColors.dividerColor.withOpacity(0.5)),
                ),

                // Tarjeta
                if (content != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: content,
                  )
                else
                  const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppColors.cardBorder, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // NAVBAR & HELPERS
  // --------------------------------------------------------------------------

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      color: const Color(0xFF413E60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, "Inicio"),
          _buildNavItem(1, Icons.people, "Clientes"),
          _buildNavItem(2, Icons.calendar_today, "Calendario"),
          _buildNavItem(
            3,
            Icons.mail,
            "Mensajes",
            badgeCount: 2,
            accentColor: const Color(0xFFFF3B30),
          ),
        ],
      ),
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
    final color = isSelected ? Colors.white : Color(0xFFAFA8D5);
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 28),
              if (badgeCount > 0)
                Positioned(
                  top: -5,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 238, 34, 34),
                      shape: BoxShape.circle,
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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DIVISOR DISCONTINUO ---
class DashedDivider extends StatelessWidget {
  final Color color;
  const DashedDivider({super.key, this.color = Colors.white24});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 35, right: 35, bottom: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
              children: List.generate(
              dashCount,
              (_) => SizedBox(
                width: dashWidth,
                height: 2,
                child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFD5D0FF))),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimeDivider extends StatelessWidget {
  final Color color;
  const TimeDivider({super.key, this.color = Colors.white24});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
            children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF655EA4))),
            ),
          ),
        );
      },
    );
  }
}
