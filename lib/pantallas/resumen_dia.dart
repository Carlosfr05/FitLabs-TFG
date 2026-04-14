import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/core/shared_widgets.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';
import 'package:pantallas_fitlabs/data/chat_service.dart';
import 'package:pantallas_fitlabs/data/cliente_service.dart';
import 'package:pantallas_fitlabs/data/progreso_service.dart';

class ResumenDiaScreen extends StatefulWidget {
  const ResumenDiaScreen({super.key});

  @override
  State<ResumenDiaScreen> createState() => _ResumenDiaScreenState();
}

class _ResumenDiaScreenState extends State<ResumenDiaScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _rutinasHoy = [];
  List<Map<String, dynamic>> _clientes = [];
  Map<int, int> _actividadSemanal = {};
  bool _cargando = true;
  int _mensajesSinLeer = 0;
  int _totalClientes = 0;
  bool _datosListos = false;

  late AnimationController _shimmerController;
  late AnimationController _staggerController;
  late AnimationController _badgeBounceController;

  // Staggered animations (5 sections)
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _badgeBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 6 sections: header, summary, activity, clients, actions, workouts
    _fadeAnims = List.generate(6, (i) {
      final start = (i * 0.10).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(6, (i) {
      final start = (i * 0.10).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _staggerController.forward();
    _cargarDatos();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _staggerController.dispose();
    _badgeBounceController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _datosListos = false;
    });
    try {
      final uid = SessionService.userId!;
      final results = await Future.wait([
        RutinaService.fetchRutinasHoy(uid),
        ChatService.fetchChats(uid),
        ClienteService.fetchMisClientes(uid),
      ]);
      if (!mounted) return;

      final chats = results[1];
      int unread = 0;
      for (final c in chats) {
        unread += (c['unread'] as int? ?? 0);
      }
      final clientes = results[2];

      // Cargar actividad semanal de todos los clientes en paralelo
      Map<int, int> weekAct = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
      if (clientes.isNotEmpty) {
        final ids = clientes
            .map((c) => (c['client'] as Map?)?['id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toList();
        if (ids.isNotEmpty) {
          final allSesiones = await Future.wait(
            ids.map((id) => ProgresoService.fetchSesionesRecientes(id, 7)),
          );
          for (final sesiones in allSesiones) {
            for (final s in sesiones) {
              final fecha = DateTime.tryParse(s['fecha']?.toString() ?? '');
              if (fecha != null) {
                weekAct[fecha.weekday] = (weekAct[fecha.weekday] ?? 0) + 1;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _rutinasHoy = results[0];
          _mensajesSinLeer = unread;
          _clientes = clientes;
          _totalClientes = clientes.length;
          _actividadSemanal = weekAct;
          _datosListos = true;
        });
        // Bounce badge si hay mensajes
        if (unread > 0) {
          _badgeBounceController.forward(from: 0);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al cargar datos. Desliza para reintentar.'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatFechaHoy() {
    final now = DateTime.now();
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    SessionService.limpiar();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.accentLila,
            backgroundColor: AppColors.surfaceColor2,
            onRefresh: () async {
              _staggerController.forward(from: 0);
              await _cargarDatos();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _staggerWrap(0, _buildHeader()),
                  const SizedBox(height: 28),
                  _staggerWrap(1, _buildSummaryCard()),
                  const SizedBox(height: 28),
                  _staggerWrap(2, _buildWeeklyActivity()),
                  const SizedBox(height: 28),
                  _staggerWrap(3, _buildClientCards()),
                  const SizedBox(height: 28),
                  _staggerWrap(
                    4,
                    _buildActionButtonsGrid(
                      AppColors.surfaceColor,
                      0,
                      AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _staggerWrap(
                    5,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entrenamientos Próximos',
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWorkoutList(
                          AppColors.textColor,
                          AppColors.subTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _staggerWrap(int index, Widget child) {
    return SlideTransition(
      position: _slideAnims[index],
      child: FadeTransition(opacity: _fadeAnims[index], child: child),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildHeader() {
    final nombre = SessionService.username?.split(' ').first ?? 'Entrenador';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E';

    return Row(
      children: [
        // Avatar con gradiente
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accentPurple, AppColors.accentLila],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              inicial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Saludo + fecha
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $nombre!',
                style: const TextStyle(
                  color: AppColors.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                _formatFechaHoy(),
                style: const TextStyle(
                  color: AppColors.dimmedColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Campana con badge real + bounce
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/mensajes'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (_mensajesSinLeer > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.3)
                        .chain(CurveTween(curve: Curves.elasticOut))
                        .animate(_badgeBounceController),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accentRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          _mensajesSinLeer > 9 ? '9+' : '$_mensajesSinLeer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Logout
        GestureDetector(
          onTap: _logout,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentLila.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del día',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _cargando
              ? _buildShimmerRow()
              : Row(
                  children: [
                    _summaryItem(
                      Icons.calendar_today_rounded,
                      '${_rutinasHoy.length}',
                      'Sesiones Hoy',
                    ),
                    _buildGradientDivider(),
                    _summaryItem(
                      Icons.people_rounded,
                      '$_totalClientes',
                      'Clientes',
                    ),
                    _buildGradientDivider(),
                    _summaryItem(
                      Icons.mail_outline_rounded,
                      '$_mensajesSinLeer',
                      'Sin leer',
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    final numValue = int.tryParse(value) ?? 0;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentLila.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentLila, size: 20),
          ),
          const SizedBox(height: 10),
          _datosListos
              ? TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: numValue),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, val, _) => Text(
                    '$val',
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.dimmedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientDivider() {
    return Container(
      width: 1,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerRow() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Row(
          children: [
            _buildShimmerMetric(),
            const SizedBox(width: 16),
            _buildShimmerMetric(),
            const SizedBox(width: 16),
            _buildShimmerMetric(),
          ],
        );
      },
    );
  }

  Widget _buildShimmerMetric() {
    return Expanded(
      child: Column(
        children: [
          _shimmerBox(40, 40, 12),
          const SizedBox(height: 10),
          _shimmerBox(36, 26, 6),
          const SizedBox(height: 6),
          _shimmerBox(52, 12, 4),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h, double r) {
    final v = _shimmerController.value;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * v, 0),
          end: Alignment(1.0 + 2.0 * v, 0),
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
      ),
    );
  }

  // --- ACTIVIDAD SEMANAL ---

  Widget _buildWeeklyActivity() {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun

    if (_cargando) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentLila.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividad de la semana',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    return Column(
                      children: [
                        _shimmerBox(28, 60, 8),
                        const SizedBox(height: 8),
                        _shimmerBox(20, 12, 4),
                      ],
                    );
                  }),
                );
              },
            ),
          ],
        ),
      );
    }

    final maxVal = _actividadSemanal.values.fold<int>(
      0,
      (a, b) => a > b ? a : b,
    );
    final maxHeight = 80.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentLila.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad de la semana',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_actividadSemanal.values.fold<int>(0, (a, b) => a + b)} sesiones',
                style: const TextStyle(
                  color: AppColors.dimmedColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final weekday = i + 1; // 1=Mon, 7=Sun
              final count = _actividadSemanal[weekday] ?? 0;
              final isToday = weekday == today;
              final barHeight = maxVal > 0 ? (count / maxVal) * maxHeight : 0.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isToday
                              ? AppColors.accentLila
                              : AppColors.dimmedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    width: 28,
                    height: barHeight.clamp(6.0, maxHeight),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: isToday
                          ? const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.accentPurple,
                                AppColors.accentLila,
                              ],
                            )
                          : null,
                      color: isToday ? null : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: isToday
                          ? AppColors.accentLila
                          : AppColors.dimmedColor,
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- CLIENTES RECIENTES ---

  Widget _buildClientCards() {
    if (_cargando) {
      return SizedBox(
        height: 100,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            return ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(3, (i) {
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      _shimmerBox(52, 52, 26),
                      const SizedBox(height: 8),
                      _shimmerBox(60, 12, 4),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      );
    }

    if (_clientes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentLila.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentLila.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.people_outline_rounded, color: AppColors.accentLila, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Sin clientes aún', style: TextStyle(color: AppColors.textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Añade tu primer cliente para empezar', style: TextStyle(color: AppColors.dimmedColor, fontSize: 13)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/clientes'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accentPurple, AppColors.accentLila]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Añadir', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    final displayClientes = _clientes.take(5).toList();
    final remaining = _clientes.length - displayClientes.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentLila.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tus clientes',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_clientes.length > 1)
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/clientes'),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: AppColors.accentLila,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayClientes.length + (remaining > 0 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayClientes.length) {
                // Card "+N más"
                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          '/clientes',
                        ),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Center(
                            child: Text(
                              '+$remaining',
                              style: const TextStyle(
                                color: AppColors.accentLila,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ver más',
                        style: TextStyle(
                          color: AppColors.dimmedColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final cliente = displayClientes[index];
              final perfil = cliente['client'] as Map<String, dynamic>?;
              final nombre =
                  perfil?['nombre'] ?? perfil?['username'] ?? 'Cliente';
              final inicial = (nombre as String).isNotEmpty
                  ? nombre[0].toUpperCase()
                  : 'C';

              return Container(
                width: 72,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    final clientId = perfil?['id'] as String?;
                    if (clientId != null) {
                      Navigator.pushNamed(context, '/clientes');
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accentPurple.withOpacity(0.6),
                              AppColors.accentLila.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            inicial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (nombre).split(' ').first,
                        style: const TextStyle(
                          color: AppColors.dimmedColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildActionButtonsGrid(Color bg, double radius, Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Añadir\ncliente',
                icon: Icons.person_add_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, '/clientes'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _actionButton(
                label: 'Crear\nrutina',
                icon: Icons.fitness_center_rounded,
                onTap: () => Navigator.pushNamed(context, '/crear-rutina'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Ver\ncalendario',
                icon: Icons.calendar_month_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, '/calendario'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _actionButton(
                label: 'Enviar\nmensaje',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, '/mensajes'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return _ScaleTapWidget(
      onTap: onTap,
      child: Container(
        height: 115,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceColor2,
              AppColors.surfaceColor2.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: AppColors.accentLila.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentLila.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.accentLila, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList(Color txt, Color subTxt) {
    if (_cargando) {
      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return Column(
            children: List.generate(2, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _shimmerBox(4, 50, 2),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(140, 16, 6),
                          const SizedBox(height: 8),
                          _shimmerBox(100, 12, 4),
                          const SizedBox(height: 6),
                          _shimmerBox(80, 12, 4),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      );
    }

    if (_rutinasHoy.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor2.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentLila.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: AppColors.accentLila.withOpacity(0.4),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin sesiones programadas hoy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pulsa "Crear rutina" para programar un entrenamiento',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dimmedColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _rutinasHoy.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _rutinasHoy[index];
        final titulo = r['title'] as String? ?? 'Sin título';
        final horaInicio = r['hora_inicio'] as String? ?? '';
        final horaFin = r['hora_fin'] as String? ?? '';
        final horario = horaInicio.isNotEmpty
            ? (horaFin.isNotEmpty
                  ? '${horaInicio.substring(0, 5)} - ${horaFin.substring(0, 5)}'
                  : horaInicio.substring(0, 5))
            : 'Sin hora';
        final clienteData = r['cliente'] as Map<String, dynamic>?;
        final clienteNombre = clienteData != null
            ? (clienteData['nombre'] ?? clienteData['username'] ?? '') as String
            : '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor2,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.accentLila, width: 4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: AppColors.dimmedColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          horario,
                          style: const TextStyle(
                            color: AppColors.dimmedColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (clienteNombre.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.dimmedColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              clienteNombre,
                              style: const TextStyle(
                                color: AppColors.dimmedColor,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accentLila.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget con micro-interacción: scale down al presionar.
class _ScaleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _ScaleTapWidget({required this.child, this.onTap});

  @override
  State<_ScaleTapWidget> createState() => _ScaleTapWidgetState();
}

class _ScaleTapWidgetState extends State<_ScaleTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
  }
}

// --- WIDGETS PERSONALIZADOS eliminados: ver lib/core/shared_widgets.dart ---
