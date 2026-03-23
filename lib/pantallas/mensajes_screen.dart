import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class MensajesScreen extends StatelessWidget {
  const MensajesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Eliminamos MaterialApp y usamos Theme para mantener la estética
    return Theme(
      data: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      child: const MessagesScreen(),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Índice 3 = Mensajes
  final int _selectedIndex = 3;

  // Datos de los chats
  final List<Map<String, dynamic>> chats = [
    {
      "name": "José Luís Sánchez González",
      "msg": "Me gustaría ver si puedes corregir...",
      "time": "08 : 52",
      "count": 1,
    },
    {
      "name": "José Luís Reina Sanchez",
      "msg": "Sin problema, paso tu sesión a las...",
      "time": "08 : 34",
      "count": 1,
    },
    {
      "name": "Juan Ruíz Marín",
      "msg": "¿Podrías revisarme estas macros?...",
      "time": "08 : 09",
      "count": 0,
    },
    {
      "name": "Coraima Medina Lechuga",
      "msg": "Te armo un mini-programa de...",
      "time": "Ayer",
      "count": 0,
    },
    {
      "name": "Carlos Luis Ramos García",
      "msg": "Entre 2 y 3 minutos de descanso...",
      "time": "Ayer",
      "count": 0,
    },
    {
      "name": "Jaime Castanedo Mateos",
      "msg": "Si te molesta la espalda baja, camb...",
      "time": "Ayer",
      "count": 0,
    },
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/resumen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/clientes');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/calendario');
        break;
      case 3:
        // Ya estamos aquí
        break;
    }
  }

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
              const SizedBox(height: 20),
              const Text(
                'Mensajes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Barra de Búsqueda
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.searchBarBg,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 15),
                      Icon(Icons.search, color: Colors.white70),
                      SizedBox(width: 10),
                      Text(
                        "Buscar Cliente",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Lista de Chats
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _buildChatCard(chat);
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // FAB
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.fabBg.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1),
          ),
          child: const Icon(
            Icons.add_comment_rounded,
            color: AppColors.textColor,
            size: 28,
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 80,
        color: AppColors.navBarBg,
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
              accentColor: AppColors.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.chatCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: AppColors.avatarBg),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat['name'],
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  chat['msg'],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat['time'],
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 5),
              if (chat['count'] > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat['count'].toString(),
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white60,
                  size: 14,
                ),
            ],
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
    final color = isSelected ? AppColors.textColor : Colors.white54;

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
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 10,
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
