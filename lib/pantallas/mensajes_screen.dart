import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF1E1A2B);
    final bgLight = const Color(0xFF352B55);
    final searchBarColor = const Color(0xFF463C6E);
    final cardColor = const Color(0xFF2E2744);
    final accentRed = const Color(0xFFFF3B30);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgLight, const Color(0xFF2A223E), bgDark],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
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
                  color: Colors.white,
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
                            hintText: 'Buscar conversación',
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

              const SizedBox(height: 20),

              // Lista de Chats
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filteredChats = _searchQuery.isEmpty
                        ? chats
                        : chats
                              .where(
                                (c) => (c['name'] as String)
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()),
                              )
                              .toList();
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filteredChats.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        return _buildChatCard(chat, cardColor, accentRed);
                      },
                    );
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
        child: GestureDetector(
          onTap: () {
            // TODO: Abrir formulario para nuevo mensaje
          },
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF6C639F).withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 1),
            ),
            child: const Icon(
              Icons.add_comment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildChatCard(
    Map<String, dynamic> chat,
    Color cardColor,
    Color accentRed,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Color(0xFFE0E0E0)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat['name'],
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: accentRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat['count'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
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
}
