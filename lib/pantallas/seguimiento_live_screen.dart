import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/progreso_service.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';

/// Pantalla donde el entrenador ve en tiempo real el progreso del cliente
/// completando una rutina.
class SeguimientoLiveScreen extends StatefulWidget {
  final String sesionId;
  final String rutinaId;
  final String clienteNombre;

  const SeguimientoLiveScreen({
    super.key,
    required this.sesionId,
    required this.rutinaId,
    required this.clienteNombre,
  });

  @override
  State<SeguimientoLiveScreen> createState() => _SeguimientoLiveScreenState();
}

class _SeguimientoLiveScreenState extends State<SeguimientoLiveScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _ejerciciosRutina = [];
  Map<String, Map<String, dynamic>> _completados = {};
  bool _cargando = true;
  bool _sesionFinalizada = false;

  RealtimeChannel? _channel;
  Timer? _pollTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _cargarDatos();
    _suscribirRealtime();
    // Polling fallback cada 5s.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refrescarEjercicios();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pollTimer?.cancel();
    if (_channel != null) {
      ProgresoService.cancelarSuscripcion(_channel!);
    }
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final ejercicios = await RutinaService.fetchEjerciciosRutina(
        widget.rutinaId,
      );
      await _refrescarEjercicios();
      if (!mounted) return;
      setState(() {
        _ejerciciosRutina = ejercicios;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _refrescarEjercicios() async {
    try {
      final data = await ProgresoService.fetchEjerciciosCompletadosDeSesion(
        widget.sesionId,
      );
      if (!mounted) return;

      final Map<String, Map<String, dynamic>> map = {};
      for (final c in data) {
        map[c['id_ejercicio_rutina'] as String] = c;
      }

      // Verificar si la sesión fue finalizada
      final sesion = await Supabase.instance.client
          .from('sesiones_completadas')
          .select('finalizada, notas')
          .eq('id', widget.sesionId)
          .maybeSingle();

      setState(() {
        _completados = map;
        _sesionFinalizada = sesion?['finalizada'] == true;
      });
    } catch (_) {}
  }

  void _suscribirRealtime() {
    _channel = ProgresoService.suscribirseASesion(
      widget.sesionId,
      (payload) => _refrescarEjercicios(),
    );
  }

  int get _totalCompletados =>
      _completados.values.where((c) => c['completado'] == true).length;

  @override
  Widget build(BuildContext context) {
    final total = _ejerciciosRutina.length;
    final pct = total > 0 ? _totalCompletados / total : 0.0;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (_cargando)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    children: [
                      _buildLiveHeader(pct, total),
                      const SizedBox(height: 20),
                      ..._ejerciciosRutina.map((ej) => _buildEjercicioLive(ej)),
                      if (_sesionFinalizada) ...[
                        const SizedBox(height: 24),
                        _buildSesionFinalizadaBanner(),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clienteNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (!_sesionFinalizada)
                      FadeTransition(
                        opacity: _pulseController,
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Text(
                      _sesionFinalizada
                          ? 'Sesión finalizada'
                          : 'Seguimiento en vivo',
                      style: TextStyle(
                        color: _sesionFinalizada
                            ? Colors.white54
                            : Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHeader(double pct, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_totalCompletados / $total ejercicios',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  color: _sesionFinalizada
                      ? Colors.greenAccent
                      : AppColors.accentLila,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                _sesionFinalizada ? Colors.greenAccent : AppColors.accentLila,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEjercicioLive(Map<String, dynamic> ej) {
    final id = ej['id'] as String;
    final completado = _completados[id];
    final isDone = completado?['completado'] == true;
    final nombre = ej['id_ejercicio_externo'] as String? ?? 'Ejercicio';
    final series = ej['serie'] as int? ?? 1;
    final reps = ej['repeticiones'] as int?;
    final peso = (ej['peso'] as num?)?.toDouble();

    final pesoReal = (completado?['peso_real'] as num?)?.toDouble();
    final repsReal = (completado?['reps_real'] as num?)?.toInt();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF2E4A3E) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isDone
            ? Border.all(color: Colors.green.shade400, width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Icono de estado
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isDone
                ? Icon(
                    Icons.check_circle,
                    key: const ValueKey('done'),
                    color: Colors.green.shade400,
                    size: 28,
                  )
                : const Icon(
                    Icons.radio_button_unchecked,
                    key: ValueKey('pending'),
                    color: Colors.white38,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${series}x${reps ?? '—'} reps · ${peso != null ? '${peso}kg' : 'Sin peso'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                if (isDone && (pesoReal != null || repsReal != null)) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Real: ${pesoReal ?? '—'}kg × ${repsReal ?? '—'} reps',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesionFinalizadaBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E4A3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.greenAccent,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Sesión completada!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalCompletados de ${_ejerciciosRutina.length} ejercicios realizados',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
