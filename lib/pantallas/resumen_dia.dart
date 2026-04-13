import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/core/shared_widgets.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';

class ResumenDiaScreen extends StatefulWidget {
  const ResumenDiaScreen({super.key});

  @override
  State<ResumenDiaScreen> createState() => _ResumenDiaScreenState();
}

class _ResumenDiaScreenState extends State<ResumenDiaScreen> {
  List<Map<String, dynamic>> _rutinasHoy = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final data = await RutinaService.fetchRutinasHoy(SessionService.userId!);
      if (mounted) setState(() => _rutinasHoy = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    SessionService.limpiar();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // --- COLORES (via AppColors) ---
    const Color bgTop = AppColors.bgTop;
    const Color bgBottom = AppColors.bgBottom;
    const Color surfaceColor = AppColors.surfaceColor;
    const Color surfaceColor2 = AppColors.surfaceColor2;
    const Color accentRed = AppColors.accentRed;
    const Color textColor = AppColors.textColor;
    const Color subTextColor = AppColors.subTextColor;
    const Color subTextColor2 = AppColors.dimmedColor;
    const Color dividerColor = AppColors.dividerColor;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, const Color(0xFF2A223E), bgBottom],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                _buildHeader(accentRed),
                const SizedBox(height: 30),

                // Resumen (Con nuevos estilos)
                _buildSummaryCard(
                  surfaceColor2,
                  0,
                  textColor,
                  subTextColor2,
                  dividerColor,
                ),
                const SizedBox(height: 30),

                // Grid Botones (Con nuevos estilos y altura)
                _buildActionButtonsGrid(surfaceColor, 0, textColor),
                const SizedBox(height: 30),

                // Título
                Text(
                  'Entrenamientos Próximos',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Lista
                _buildWorkoutList(textColor, subTextColor),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildHeader(Color accentRed) {
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
                      color: accentRed,
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
            const SizedBox(width: 15),
            GestureDetector(
              onTap: _logout,
              child: const Icon(Icons.logout, color: Colors.white70, size: 24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    Color bg,
    double radius,
    Color txt,
    Color subTxt,
    Color div,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      // Aplicamos el nuevo color y radio
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del día',
            style: TextStyle(
              color: txt,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _item(
                '${_rutinasHoy.where((r) => r['hora_fin'] != null).length}',
                'Sesiones Realizadas',
                txt,
                subTxt,
              ),
              Container(
                height: 40,
                width: 1,
                color: div,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              _item('${_rutinasHoy.length}', 'Sesiones Hoy', txt, subTxt),
              Container(
                height: 40,
                width: 1,
                color: div,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              _item('0', 'Mensajes sin leer', txt, subTxt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String val, String label, Color txt, Color subTxt) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              color: txt,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: subTxt, fontSize: 12),
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
              child: _btn(
                'Añadir nuevo\ncliente',
                Icons.person_add,
                bg,
                radius,
                textColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _btn(
                'Crear nueva\nrutina',
                Icons.fitness_center,
                bg,
                radius,
                textColor,
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
            Expanded(
              child: _btn(
                'Modificar rutina\nexistente',
                Icons.edit,
                bg,
                radius,
                textColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _btn(
                'Revisar pagos\nde clientes',
                Icons.monetization_on,
                bg,
                radius,
                textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _btn(
    String label,
    IconData? icon,
    Color bg,
    double radius,
    Color txt, {
    bool showPlus = false,
    VoidCallback? onTap, // <--- Añadimos este parámetro
  }) {
    return InkWell(
      // <--- Envolvemos todo en InkWell para el efecto visual de clic
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        height: 65,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: txt,
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

  Widget _buildWorkoutList(Color txt, Color subTxt) {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(color: AppColors.accentLila),
        ),
      );
    }

    if (_rutinasHoy.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_available, color: Colors.white30, size: 48),
            SizedBox(height: 12),
            Text(
              'No hay entrenamientos programados para hoy',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _rutinasHoy.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: DashedDivider(),
      ),
      itemBuilder: (context, index) {
        final r = _rutinasHoy[index];
        final titulo = r['title'] as String? ?? 'Sin título';
        final horaInicio = r['hora_inicio'] as String? ?? '';
        final horaFin = r['hora_fin'] as String? ?? '';
        final horario = horaInicio.isNotEmpty
            ? (horaFin.isNotEmpty ? '$horaInicio - $horaFin' : horaInicio)
            : 'Sin hora';
        final clienteData = r['cliente'] as Map<String, dynamic>?;
        final clienteNombre = clienteData != null
            ? (clienteData['nombre'] ?? clienteData['username'] ?? '') as String
            : '';

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
                      titulo,
                      style: TextStyle(
                        color: txt,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(horario, style: TextStyle(color: txt, fontSize: 14)),
                    if (clienteNombre.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        clienteNombre,
                        style: TextStyle(color: subTxt, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- WIDGETS PERSONALIZADOS eliminados: ver lib/core/shared_widgets.dart ---
