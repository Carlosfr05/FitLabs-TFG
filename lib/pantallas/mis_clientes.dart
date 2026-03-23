import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/pantallas/detalle_cliente.dart';

class MisClientesScreen extends StatelessWidget {
  const MisClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      child: const ClientsScreen(),
    );
  }
}

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  // Índice 1 = Clientes
  int _selectedIndex = 1;

  final List<Map<String, dynamic>> clients = [
    {
      "name": "José Luís Sánchez González",
      "status": "Nuevos mensajes",
      "isBoldStatus": true,
      "msgCount": 1,
      "hasTraining": true,
    },
    {
      "name": "Juan Ruíz Marín",
      "status": "Resultados de sesiones sin leer",
      "isBoldStatus": true,
      "msgCount": 1,
      "hasTraining": true,
    },
    {
      "name": "José Luís Reina Sanchez",
      "status": "Nuevos mensajes",
      "isBoldStatus": true,
      "msgCount": 1,
      "hasTraining": true,
    },
    {
      "name": "Coraima Medina Lechuga",
      "status": "Próxima sesión - Comienza a las 13 : 10",
      "isBoldStatus": false,
      "msgCount": 0,
      "hasTraining": true,
    },
    {
      "name": "Carlos Luis Ramos García",
      "status": "Próxima sesión - Comienza a las 09 : 30",
      "isBoldStatus": false,
      "msgCount": 0,
      "hasTraining": true,
    },
    {
      "name": "Jaime Castanedo Mateos",
      "status": "Próxima sesión - Comienza a las 11 : 00",
      "isBoldStatus": false,
      "msgCount": 0,
      "hasTraining": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Paleta de colores

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Mis Clientes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // --- Barra de Búsqueda ---
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

                const SizedBox(height: 25),

                // --- Filtros ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Todos tus clientes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navBarBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              "Ordenar por: Recientes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // --- Lista de Clientes ---
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: clients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return _buildClientRow(client, AppColors.accentRed);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // --- FAB ---
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_alt_1,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),

      // --- Barra de Navegación ---
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // Usamos Navigator del contexto padre (el que está en main.dart)
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/resumen');
        break;
      case 1:
        // Ya estamos aquí
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/calendario');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/mensajes');
        break;
    }
  }

  Widget _buildClientRow(Map<String, dynamic> client, Color accentRed) {
    // 1. Envolvemos todo en un GestureDetector para detectar el clic
    return GestureDetector(
      onTap: () {
        // 2. Comprobamos si el nombre coincide
        if (client['name'] == "Juan Ruíz Marín") {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Aquí pones la pantalla a la que quieres ir
              builder: (context) => const DetalleClienteScreen(),
            ),
          );
        } else {
          // Opcional: Lógica para los demás clientes
          print("Se pulsó otro cliente: ${client['name']}");
        }
      },
      // Para que el clic funcione en toda el área, no solo sobre el texto/iconos
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          const Image(
            image: AssetImage('assets/images/imagenPerfil.png'),
            width: 50,
            height: 50,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  client['status'],
                  style: TextStyle(
                    color: client['isBoldStatus']
                        ? Colors.white
                        : Colors.white60,
                    fontWeight: client['isBoldStatus']
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white70,
                    size: 22,
                  ),
                  if (client['msgCount'] > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: accentRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bgBottom,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Center(
                          child: Text(
                            client['msgCount'].toString(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              const Icon(Icons.fitness_center, color: Colors.white70, size: 24),
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
    final color = isSelected ? Colors.white : AppColors.navIconUnselected;

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
                        color: Colors.white,
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
