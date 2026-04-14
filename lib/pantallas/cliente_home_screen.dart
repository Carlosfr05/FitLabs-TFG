import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';
import 'package:pantallas_fitlabs/data/progreso_service.dart';
import 'package:pantallas_fitlabs/pantallas/completar_rutina_screen.dart';

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  List<Map<String, dynamic>> _rutinasHoy = [];
  List<Map<String, dynamic>> _todasRutinas = [];
  bool _cargando = true;
  int _sesionesCompletadas = 0;
  int _rachaSemanal = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final uid = SessionService.userId!;
      final hoy = await RutinaService.fetchRutinasHoy(uid);
      final todas = await RutinaService.fetchRutinasCliente(uid);
      final sesiones = await ProgresoService.contarSesionesCompletadas(uid);
      final racha = await ProgresoService.calcularRachaSemanal(uid);
      if (mounted) {
        setState(() {
          _rutinasHoy = hoy;
          _todasRutinas = todas;
          _sesionesCompletadas = sesiones;
          _rachaSemanal = racha;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirCompletarRutina(Map<String, dynamic> rutina) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompletarRutinaScreen(
          rutinaId: rutina['id'] as String,
          rutinaTitle: rutina['title'] as String? ?? 'Sin título',
        ),
      ),
    );
    if (result == true) _cargarDatos();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    SessionService.limpiar();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final nombre = SessionService.username ?? 'Cliente';

    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, $nombre!',
                            style: const TextStyle(
                              color: AppColors.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Aquí tienes tu plan de hoy',
                            style: TextStyle(
                              color: AppColors.subTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _logout,
                          child: const Icon(
                            Icons.logout,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Rutina del día
                _buildSectionTitle('Rutina de hoy'),
                const SizedBox(height: 15),
                if (_cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: AppColors.accentLila,
                      ),
                    ),
                  )
                else if (_rutinasHoy.isEmpty)
                  _buildEmptyCard(
                    icon: Icons.fitness_center,
                    title: 'Sin rutina asignada',
                    subtitle:
                        'Tu entrenador aún no te ha asignado una rutina para hoy.',
                  )
                else
                  ..._rutinasHoy.map(
                    (r) => _buildRutinaCard(r, showComplete: true),
                  ),
                const SizedBox(height: 30),

                // Próximas sesiones
                _buildSectionTitle('Próximas sesiones'),
                const SizedBox(height: 15),
                if (_todasRutinas.where((r) {
                  final fecha = r['fecha'] as String?;
                  if (fecha == null) return false;
                  return fecha.compareTo(
                        DateTime.now().toIso8601String().split('T')[0],
                      ) >
                      0;
                }).isEmpty)
                  _buildEmptyCard(
                    icon: Icons.calendar_today,
                    title: 'Sin sesiones programadas',
                    subtitle:
                        'Cuando tu entrenador programe sesiones, aparecerán aquí.',
                  )
                else
                  ..._todasRutinas
                      .where((r) {
                        final fecha = r['fecha'] as String?;
                        if (fecha == null) return false;
                        return fecha.compareTo(
                              DateTime.now().toIso8601String().split('T')[0],
                            ) >
                            0;
                      })
                      .take(3)
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRutinaCard(r),
                        ),
                      ),
                const SizedBox(height: 30),

                // Mi progreso
                _buildSectionTitle('Mi progreso'),
                const SizedBox(height: 15),
                _buildProgressCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentLila, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.subTextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRutinaCard(
    Map<String, dynamic> rutina, {
    bool showComplete = false,
  }) {
    final titulo = rutina['title'] as String? ?? 'Sin título';
    final fecha = rutina['fecha'] as String? ?? '';
    final horaInicio = rutina['hora_inicio'] as String? ?? '';
    final horaFin = rutina['hora_fin'] as String? ?? '';
    final horario = horaInicio.isNotEmpty
        ? (horaFin.isNotEmpty ? '$horaInicio - $horaFin' : horaInicio)
        : '';
    final creador = rutina['creador'] as Map<String, dynamic>?;
    final trainerName = creador != null
        ? (creador['nombre'] ?? creador['username'] ?? '') as String
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.accentLila, width: 4),
        ),
      ),
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
          if (horario.isNotEmpty || fecha.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (fecha.isNotEmpty) fecha,
                if (horario.isNotEmpty) horario,
              ].join(' \u00b7 '),
              style: const TextStyle(
                color: AppColors.subTextColor,
                fontSize: 12,
              ),
            ),
          ],
          if (trainerName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Por: $trainerName',
              style: const TextStyle(
                color: AppColors.dimmedColor,
                fontSize: 11,
              ),
            ),
          ],
          if (showComplete) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _abrirCompletarRutina(rutina),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Completar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _progressItem('$_sesionesCompletadas', 'Sesiones\ncompletadas'),
          Container(
            height: 40,
            width: 1,
            color: AppColors.dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          _progressItem('${_todasRutinas.length}', 'Rutinas\nasignadas'),
          Container(
            height: 40,
            width: 1,
            color: AppColors.dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          _progressItem(
            _rachaSemanal > 0 ? '$_rachaSemanal' : '—',
            'Racha\nsemanal',
          ),
        ],
      ),
    );
  }

  Widget _progressItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subTextColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
