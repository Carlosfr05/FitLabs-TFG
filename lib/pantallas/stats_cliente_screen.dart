import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/progreso_service.dart';

/// Pantalla de estadísticas detalladas de un cliente (para el entrenador).
class StatsClienteScreen extends StatefulWidget {
  final String clientId;
  final String clienteNombre;

  const StatsClienteScreen({
    super.key,
    required this.clientId,
    required this.clienteNombre,
  });

  @override
  State<StatsClienteScreen> createState() => _StatsClienteScreenState();
}

class _StatsClienteScreenState extends State<StatsClienteScreen> {
  bool _cargando = true;

  // Datos
  int _totalSesiones = 0;
  int _rachaSemanal = 0;
  double _cumplimiento = 0;
  double _volumenSemanal = 0;
  List<Map<String, dynamic>> _volumenPorSesion = [];
  List<Map<String, dynamic>> _sesionesRecientes = [];
  List<Map<String, dynamic>> _mejoras = [];

  @override
  void initState() {
    super.initState();
    _cargarStats();
  }

  Future<void> _cargarStats() async {
    try {
      final results = await Future.wait([
        ProgresoService.contarSesionesCompletadas(widget.clientId),
        ProgresoService.calcularRachaSemanal(widget.clientId),
        ProgresoService.calcularCumplimiento(widget.clientId),
        ProgresoService.calcularVolumenSemanal(widget.clientId),
        ProgresoService.fetchVolumenPorSesion(widget.clientId, limite: 10),
        ProgresoService.fetchSesionesRecientes(widget.clientId, 30),
        ProgresoService.fetchProgresoEjercicios(widget.clientId),
      ]);

      if (!mounted) return;
      setState(() {
        _totalSesiones = results[0] as int;
        _rachaSemanal = results[1] as int;
        _cumplimiento = results[2] as double;
        _volumenSemanal = results[3] as double;
        _volumenPorSesion = results[4] as List<Map<String, dynamic>>;
        _sesionesRecientes = results[5] as List<Map<String, dynamic>>;
        _mejoras = results[6] as List<Map<String, dynamic>>;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 20),
                      _buildVolumenChart(),
                      const SizedBox(height: 20),
                      _buildFrecuenciaChart(),
                      if (_mejoras.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildMejorasSection(),
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
                const Text(
                  'Estadísticas',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.fitness_center,
            '$_totalSesiones',
            'Sesiones',
            Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            Icons.local_fire_department,
            '$_rachaSemanal',
            'Racha sem.',
            Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            Icons.check_circle_outline,
            '${_cumplimiento.toStringAsFixed(0)}%',
            'Cumplim.',
            Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            Icons.trending_up,
            _volumenSemanal > 1000
                ? '${(_volumenSemanal / 1000).toStringAsFixed(1)}k'
                : _volumenSemanal.toStringAsFixed(0),
            'Vol. sem.',
            AppColors.accentLila,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumenChart() {
    if (_volumenPorSesion.isEmpty) {
      return _buildEmptyChart('Volumen por sesión', 'Sin datos aún');
    }

    final spots = _volumenPorSesion.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['volumen'] as num).toDouble());
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volumen por sesión (kg×reps)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.white12, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v >= 1000
                            ? '${(v / 1000).toStringAsFixed(1)}k'
                            : v.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= 0 && i < _volumenPorSesion.length) {
                          final fecha =
                              _volumenPorSesion[i]['fecha'] as String?;
                          if (fecha != null && fecha.length >= 10) {
                            return Text(
                              '${fecha.substring(8, 10)}/${fecha.substring(5, 7)}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.accentLila,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.accentLila,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accentLila.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrecuenciaChart() {
    // Agrupar sesiones recientes por semana
    final Map<String, int> porSemana = {};
    for (final s in _sesionesRecientes) {
      final fecha = DateTime.tryParse(s['fecha'] ?? '');
      if (fecha != null) {
        // Semana del mes
        final weekStart = fecha.subtract(Duration(days: fecha.weekday - 1));
        final key =
            '${weekStart.day.toString().padLeft(2, '0')}/${weekStart.month.toString().padLeft(2, '0')}';
        porSemana[key] = (porSemana[key] ?? 0) + 1;
      }
    }

    if (porSemana.isEmpty) {
      return _buildEmptyChart('Frecuencia semanal', 'Sin datos aún');
    }

    final entries = porSemana.entries.toList();
    final maxY = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frecuencia semanal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.white12, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= 0 && i < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              entries[i].key,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: maxY + 1,
                barGroups: entries.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        color: AppColors.accentLila,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMejorasSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Mejoras recientes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._mejoras.map((m) {
            final pesoAntes = m['peso_antes'] as double;
            final pesoAhora = m['peso_ahora'] as double;
            final repsAntes = m['reps_antes'] as int;
            final repsAhora = m['reps_ahora'] as int;
            final nombre = m['id_ejercicio_rutina'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nombre,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pesoAhora > pesoAntes)
                    Text(
                      '$pesoAntes→${pesoAhora}kg',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (pesoAhora > pesoAntes && repsAhora > repsAntes)
                    const Text(' · ', style: TextStyle(color: Colors.white38)),
                  if (repsAhora > repsAntes)
                    Text(
                      '$repsAntes→$repsAhora reps',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          const Icon(Icons.bar_chart, color: Colors.white24, size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
