import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/core/shared_widgets.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();

  static const List<String> _monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
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
              const DashedDivider(
                padding: EdgeInsets.only(left: 40, right: 40, bottom: 20),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGETS DEL CALENDARIO (Corregido con GridView)
  // --------------------------------------------------------------------------

  Widget _buildCalendarWidget() {
    const List<String> weekDays = [
      "lun",
      "mar",
      "mie",
      "jue",
      "vie",
      "sab",
      "dom",
    ];

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final startOffset = firstDay.weekday - 1; // 0=lun, 6=dom
    final today = DateTime.now();

    final List<Map<String, dynamic>> days = [];

    // Días del mes anterior para rellenar la primera fila
    for (int i = startOffset; i > 0; i--) {
      final d = firstDay.subtract(Duration(days: i));
      days.add({'date': d, 'current': false});
    }

    // Días del mes actual
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      final isSelected =
          date.year == _selectedDay.year &&
          date.month == _selectedDay.month &&
          date.day == _selectedDay.day;
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      days.add({
        'date': date,
        'current': true,
        'selected': isSelected,
        'today': isToday,
      });
    }

    // Días del mes siguiente para completar la última fila
    final trailing = days.length % 7 == 0 ? 0 : 7 - (days.length % 7);
    for (int i = 1; i <= trailing; i++) {
      days.add({
        'date': DateTime(_currentMonth.year, _currentMonth.month + 1, i),
        'current': false,
      });
    }

    final monthLabel =
        '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Selector de Mes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month - 1,
                  );
                }),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.dimmedColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                monthLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () => setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month + 1,
                  );
                }),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.dimmedColor,
                  size: 14,
                ),
              ),
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

          // Grilla de días
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 0,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, index) {
              final dayData = days[index];
              final isCurrent = dayData['current'] as bool;
              return Center(
                child: GestureDetector(
                  onTap: isCurrent
                      ? () => setState(
                          () => _selectedDay = dayData['date'] as DateTime,
                        )
                      : null,
                  child: _buildDayCell(
                    (dayData['date'] as DateTime).day.toString(),
                    isCurrentMonth: isCurrent,
                    isSelected: dayData['selected'] ?? false,
                    isToday: dayData['today'] ?? false,
                  ),
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
    bool isToday = false,
  }) {
    const double size = 35;
    Color? bgColor;
    if (isSelected) {
      bgColor = AppColors.accentLila.withValues(alpha: 0.8);
    } else if (isToday) {
      bgColor = Colors.white.withValues(alpha: 0.15);
    }
    return Container(
      width: size,
      height: size,
      decoration: bgColor != null
          ? BoxDecoration(color: bgColor, shape: BoxShape.circle)
          : null,
      alignment: Alignment.center,
      child: Text(
        day,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isCurrentMonth ? Colors.white : AppColors.dimmedColor),
          fontSize: 13,
          fontWeight: (isSelected || isToday)
              ? FontWeight.bold
              : FontWeight.normal,
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
                Text(
                  time,
                  style: TextStyle(color: AppColors.textColor, fontSize: 12),
                ),
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
                  child: TimeDivider(
                    color: AppColors.dividerColor.withValues(alpha: 0.5),
                  ),
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
            color: Colors.black.withValues(alpha: 0.2),
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
}
