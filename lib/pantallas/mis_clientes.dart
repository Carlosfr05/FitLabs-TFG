import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/data/cliente_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/pantallas/detalle_cliente.dart';
import 'package:pantallas_fitlabs/pantallas/buscar_clientes_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _clientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargando = true);
    try {
      final data = await ClienteService.fetchMisClientes(
        SessionService.userId!,
      );
      if (mounted) setState(() => _clientes = data);
    } catch (_) {
      // Silenciar error
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarDialogoInvitar() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BuscarClientesScreen()),
    );

    if (added == true && mounted) {
      _cargarClientes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Paleta de colores
    final bgTop = const Color(0xFF352B55);
    final bgBottom = const Color(0xFF1E1A2B);
    final searchBarColor = const Color(0xFF4B4584);
    final filterPillColor = const Color(0xFF413E60);
    const navIndex = 1;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          AppBottomNavBar.handleHorizontalSwipe(context, navIndex, details);
        },
        child: Container(
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
                    child: _cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFAEA6E8),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final filteredClients = _searchQuery.isEmpty
                                  ? _clientes
                                  : _clientes.where((c) {
                                      final perfil =
                                          c['client'] as Map<String, dynamic>?;
                                      final nombre =
                                          (perfil?['nombre'] ??
                                                  perfil?['username'] ??
                                                  '')
                                              as String;
                                      return nombre.toLowerCase().contains(
                                        _searchQuery.toLowerCase(),
                                      );
                                    }).toList();

                              if (filteredClients.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        color: Colors.white30,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'Sin resultados'
                                            : 'Aún no tienes clientes\nPulsa + para invitar uno',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return RefreshIndicator(
                                onRefresh: _cargarClientes,
                                color: const Color(0xFFAEA6E8),
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    20,
                                  ),
                                  itemCount: filteredClients.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 20),
                                  itemBuilder: (context, index) {
                                    final rel = filteredClients[index];
                                    return _buildClientRow(rel);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // --- FAB ---
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: GestureDetector(
          onTap: _mostrarDialogoInvitar,
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: navIndex),
    );
  }

  Widget _buildClientRow(Map<String, dynamic> relacion) {
    final perfil = relacion['client'] as Map<String, dynamic>? ?? {};
    final nombre =
        (perfil['nombre'] ?? perfil['username'] ?? 'Sin nombre') as String;
    final clientId = perfil['id'] as String?;

    return GestureDetector(
      onTap: () {
        if (clientId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalleClienteScreen(clientId: clientId, clientName: nombre),
            ),
          );
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF4B4584),
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
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
                  'Cliente activo',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white70, size: 24),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white30,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
