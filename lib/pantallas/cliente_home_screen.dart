import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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

                // Rutina del día (placeholder)
                _buildSectionTitle('Rutina de hoy'),
                const SizedBox(height: 15),
                _buildEmptyCard(
                  icon: Icons.fitness_center,
                  title: 'Sin rutina asignada',
                  subtitle:
                      'Tu entrenador aún no te ha asignado una rutina para hoy.',
                ),
                const SizedBox(height: 30),

                // Próximas sesiones
                _buildSectionTitle('Próximas sesiones'),
                const SizedBox(height: 15),
                _buildEmptyCard(
                  icon: Icons.calendar_today,
                  title: 'Sin sesiones programadas',
                  subtitle:
                      'Cuando tu entrenador programe sesiones, aparecerán aquí.',
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
          _progressItem('0', 'Sesiones\ncompletadas'),
          Container(
            height: 40,
            width: 1,
            color: AppColors.dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          _progressItem('0', 'Rutinas\nasignadas'),
          Container(
            height: 40,
            width: 1,
            color: AppColors.dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          _progressItem('—', 'Racha\nsemanal'),
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
