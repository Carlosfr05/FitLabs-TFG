import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/core/shared_widgets.dart';
import 'package:pantallas_fitlabs/data/progreso_service.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/pantallas/crear_rutina.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen>
    with TickerProviderStateMixin {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();

  List<Map<String, dynamic>> _eventosDia = [];
  bool _cargandoEventos = true;

  // Indicadores: día → lista de rutina IDs para ese día
  Map<int, List<String>> _diasConEventos = {};
  // Rutinas completadas: rutina_id → bool
  Map<String, bool> _rutinasCompletadas = {};

  // PageController para swipe horizontal de meses
  late PageController _pageController;
  static const int _initialPage = 500;

  // Animaciones stagger
  late AnimationController _staggerCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();

    // Stagger animations (4 secciones: header, calendario, divider, eventos)
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnims = List.generate(4, (i) {
      return CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(i * 0.12, 0.5 + i * 0.12, curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(4, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(i * 0.12, 0.5 + i * 0.12, curve: Curves.easeOutCubic),
      ));
    });

    _pageController = PageController(initialPage: _initialPage);

    _staggerCtrl.forward();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  DateTime _monthFromPage(int page) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + (page - _initialPage));
  }

  Future<void> _cargarDatosIniciales() async {
    await Future.wait([
      _cargarEventos(),
      _cargarIndicadoresMes(),
    ]);
  }

  Future<void> _cargarEventos() async {
    setState(() => _cargandoEventos = true);
    try {
      final fecha = _selectedDay.toIso8601String().split('T')[0];
      final data = await RutinaService.fetchRutinasPorFecha(
        SessionService.userId!,
        fecha,
      );

      // Verificar estado completado de cada rutina
      final Map<String, bool> completadas = {};
      for (final r in data) {
        final rutinaId = r['id'] as String;
        final clienteId = r['assigned_client_id'] as String?;
        if (clienteId != null) {
          try {
            completadas[rutinaId] = await ProgresoService.rutinaCompletadaHoy(
              rutinaId, clienteId,
            );
          } catch (_) {
            completadas[rutinaId] = false;
          }
        }
      }

      if (mounted) {
        setState(() {
          _eventosDia = data;
          _rutinasCompletadas = completadas;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargandoEventos = false);
    }
  }

  Future<void> _cargarIndicadoresMes() async {
    try {
      final rutinas = await RutinaService.fetchRutinasPorMes(
        SessionService.userId!,
        _currentMonth,
      );

      final Map<int, List<String>> dias = {};
      for (final r in rutinas) {
        final fecha = r['fecha'] as String?;
        if (fecha != null) {
          final dt = DateTime.tryParse(fecha);
          if (dt != null) {
            dias.putIfAbsent(dt.day, () => []);
            dias[dt.day]!.add(r['id'] as String);
          }
        }
      }

      if (mounted) setState(() => _diasConEventos = dias);
    } catch (_) {}
  }

  void _irAHoy() {
    _pageController.animateToPage(
      _initialPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDay = now;
    });
    _cargarEventos();
    _cargarIndicadoresMes();
  }

  bool get _esMesActual {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  String _calcularDuracion(String? horaInicio, String? horaFin) {
    if (horaInicio == null || horaFin == null) return '';
    try {
      final partsI = horaInicio.split(':');
      final partsF = horaFin.split(':');
      final ini = int.parse(partsI[0]) * 60 + int.parse(partsI[1]);
      final fin = int.parse(partsF[0]) * 60 + int.parse(partsF[1]);
      final diff = fin - ini;
      if (diff <= 0) return '';
      if (diff >= 60) return '${diff ~/ 60}h ${diff % 60 > 0 ? '${diff % 60}min' : ''}';
      return '${diff}min';
    } catch (_) {
      return '';
    }
  }

  IconData _iconoPorTitulo(String titulo) {
    final t = titulo.toLowerCase();
    if (t.contains('cardio') || t.contains('hiit') || t.contains('running')) {
      return Icons.directions_run_rounded;
    }
    if (t.contains('yoga') || t.contains('stretch') || t.contains('flexib')) {
      return Icons.self_improvement_rounded;
    }
    if (t.contains('core') || t.contains('abdom')) {
      return Icons.accessibility_new_rounded;
    }
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 300),
            child: Column(
              children: [
                _staggerWrap(0, _buildHeader()),
                const SizedBox(height: 12),
                _staggerWrap(1, _buildCalendar()),
                _staggerWrap(2, Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 0.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.accentLila.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.accentLila.withValues(alpha: 0.3),
                          size: 16,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 0.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentLila.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                _staggerWrap(3, _buildEventSection()),
              ],
            ),
          ),
        ),
      ),

      // FAB solo para entrenadores
      floatingActionButton: SessionService.isEntrenador
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrearRutinaScreen(initialDate: _selectedDay),
                    ),
                  );
                  _cargarEventos();
                  _cargarIndicadoresMes();
                },
                backgroundColor: AppColors.accentPurple,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            )
          : null,

      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _staggerWrap(int index, Widget child) {
    return SlideTransition(
      position: _slideAnims[index],
      child: FadeTransition(
        opacity: _fadeAnims[index],
        child: child,
      ),
    );
  }

  // ──────────── HEADER ────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentLila],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tus entrenamientos organizados',
                  style: TextStyle(color: AppColors.dimmedColor, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!_esMesActual)
            GestureDetector(
              onTap: _irAHoy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentLila.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.today_rounded, color: AppColors.accentLila, size: 16),
                    SizedBox(width: 4),
                    Text('Hoy', style: TextStyle(color: AppColors.accentLila, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────── CALENDARIO ────────────
  void _cambiarMes(int delta) {
    _pageController.animateToPage(
      _pageController.page!.round() + delta,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildCalendar() {
    const List<String> weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final monthLabel = '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Mes label con flechas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _cambiarMes(-1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: AppColors.dimmedColor, size: 20),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                monthLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _cambiarMes(1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: AppColors.dimmedColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cabecera días semana
          Row(
            children: weekDays.map((d) => Expanded(
              child: Center(
                child: Text(d, style: TextStyle(
                  color: (d == 'S' || d == 'D') ? AppColors.accentLila.withValues(alpha: 0.7) : Colors.white60,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
              ),
            )).toList(),
          ),
          const SizedBox(height: 6),

          // Grilla con PageView para swipe horizontal
          LayoutBuilder(
            builder: (context, constraints) {
              final cellW = constraints.maxWidth / 7;
              final cellH = cellW / 1.05;
              // Calcular filas reales del mes actual
              final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
              final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
              final startOffset = firstDay.weekday - 1;
              final totalCells = startOffset + daysInMonth;
              final rows = (totalCells / 7).ceil();
              final gridHeight = cellH * rows;

              return SizedBox(
                height: gridHeight,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    final month = _monthFromPage(page);
                    setState(() {
                      _currentMonth = month;
                      _selectedDay = DateTime(month.year, month.month, 1);
                    });
                    _cargarEventos();
                    _cargarIndicadoresMes();
                  },
                  itemBuilder: (context, page) {
                    return _buildMonthGrid(_monthFromPage(page));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    final List<Map<String, dynamic>> days = [];

    for (int i = startOffset; i > 0; i--) {
      final d = firstDay.subtract(Duration(days: i));
      days.add({'date': d, 'current': false});
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final isSelected = date.year == _selectedDay.year &&
          date.month == _selectedDay.month &&
          date.day == _selectedDay.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      days.add({
        'date': date,
        'current': true,
        'selected': isSelected,
        'today': isToday,
        'day': d,
      });
    }

    final trailing = days.length % 7 == 0 ? 0 : 7 - (days.length % 7);
    for (int i = 1; i <= trailing; i++) {
      days.add({
        'date': DateTime(month.year, month.month + 1, i),
        'current': false,
      });
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final dayData = days[index];
        final isCurrent = dayData['current'] as bool;
        final dayNum = (dayData['date'] as DateTime).day;
        final hasEvents = isCurrent && _diasConEventos.containsKey(dayNum);

        return GestureDetector(
          onTap: isCurrent
              ? () {
                  setState(() => _selectedDay = dayData['date'] as DateTime);
                  _cargarEventos();
                }
              : null,
          child: _buildDayCell(
            dayNum.toString(),
            isCurrentMonth: isCurrent,
            isSelected: dayData['selected'] ?? false,
            isToday: dayData['today'] ?? false,
            hasEvents: hasEvents,
          ),
        );
      },
    );
  }

  Widget _buildDayCell(
    String day, {
    bool isCurrentMonth = true,
    bool isSelected = false,
    bool isToday = false,
    bool hasEvents = false,
  }) {
    const double size = 30;
    Color? bgColor;
    if (isSelected) {
      bgColor = AppColors.accentPurple;
    } else if (isToday) {
      bgColor = Colors.white.withValues(alpha: 0.1);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: AppColors.accentLila.withValues(alpha: 0.5), width: 1.5)
                : null,
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.accentPurple.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(day, style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isCurrentMonth ? Colors.white : Colors.white24),
            fontSize: 13,
            fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
          )),
        ),
        const SizedBox(height: 2),
        // Indicador de eventos
        if (hasEvents)
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.accentLila,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  // ──────────── LISTA DE EVENTOS ────────────
  Widget _buildEventSection() {
    if (_cargandoEventos) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentLila),
        ),
      );
    }

    if (_eventosDia.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded, color: Colors.white24, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin entrenamientos',
              style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'No hay sesiones para el ${_selectedDay.day} de ${_monthNames[_selectedDay.month - 1]}',
              style: const TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _eventosDia.asMap().entries.map((entry) {
          return _buildEventRow(entry.value, entry.key);
        }).toList(),
      ),
    );
  }

  Widget _buildEventRow(Map<String, dynamic> rutina, int index) {
    final titulo = rutina['title'] as String? ?? 'Sin título';
    final horaInicio = rutina['hora_inicio'] as String? ?? '';
    final horaFin = rutina['hora_fin'] as String? ?? '';
    final clienteData = rutina['cliente'] as Map<String, dynamic>?;
    final clienteNombre = clienteData != null
        ? (clienteData['nombre'] ?? clienteData['username'] ?? '') as String
        : '';
    final rutinaId = rutina['id'] as String;
    final completada = _rutinasCompletadas[rutinaId] ?? false;
    final horaLabel = horaInicio.isNotEmpty
        ? horaInicio.substring(0, 5)
        : '--:--';
    final duracion = _calcularDuracion(
      horaInicio.isNotEmpty ? horaInicio : null,
      horaFin.isNotEmpty ? horaFin : null,
    );
    final icono = _iconoPorTitulo(titulo);

    final accentColor = completada
        ? const Color(0xFF4CAF50)
        : AppColors.accentLila;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hora a la izquierda
          SizedBox(
            width: 48,
            child: Text(
              horaLabel,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Tarjeta
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                children: [
                  // Icono tipo
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icono, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Título + cliente + duración
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        )),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (clienteNombre.isNotEmpty) ...[
                              const Icon(Icons.person_outline, color: Colors.white38, size: 13),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(clienteNombre, style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            if (clienteNombre.isNotEmpty && duracion.isNotEmpty)
                              const SizedBox(width: 10),
                            if (duracion.isNotEmpty) ...[
                              const Icon(Icons.timer_outlined, color: Colors.white38, size: 13),
                              const SizedBox(width: 3),
                              Text(duracion, style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              )),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: completada
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                          : const Color(0xFFFF9800).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      completada ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      color: completada ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
