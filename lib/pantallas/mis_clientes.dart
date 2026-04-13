import 'package:flutter/material.dart';
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
  final int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final bgTop = const Color(0xFF352B55);
    final bgBottom = const Color(0xFF1E1A2B);
    final searchBarColor = const Color(0xFF4B4584);
    final filterPillColor = const Color(0xFF413E60);
    final navBarColor = const Color(0xFF413E60);
    final accentRed = const Color(0xFFFF3B30);

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
                      color: searchBarColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 15),
                        const Icon(Icons.search, color: Colors.white70),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Buscar Cliente',
                              hintStyle: TextStyle(color: Colors.white70),
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.clear,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
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
                          color: filterPillColor,
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
                  child: Builder(
                    builder: (context) {
                      final filteredClients = _searchQuery.isEmpty
                          ? clients
                          : clients
                                .where(
                                  (c) => (c['name'] as String)
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()),
                                )
                                .toList();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: filteredClients.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final client = filteredClients[index];
                          return _buildClientRow(client, accentRed);
                        },
                      );
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
        child: GestureDetector(
          onTap: () {
            // TODO: Abrir formulario para añadir cliente
          },
          child: Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              color: Color(0xFF776DAE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),

      // --- Barra de Navegación ---
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 80,
          color: navBarColor,
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
                accentColor: accentRed,
              ),
            ],
          ),
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DetalleClienteScreen()),
        );
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
                            color: const Color(0xFF1E1A2B),
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
    final color = isSelected ? Colors.white : Color(0xFFAFA8D5);

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
                      border: Border.all(
                        color: const Color(0xFF332D43),
                        width: 1.5,
                      ),
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
