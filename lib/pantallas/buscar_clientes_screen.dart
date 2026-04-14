import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/cliente_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'dart:async';

class BuscarClientesScreen extends StatefulWidget {
  const BuscarClientesScreen({super.key});

  @override
  State<BuscarClientesScreen> createState() => _BuscarClientesScreenState();
}

class _BuscarClientesScreenState extends State<BuscarClientesScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isTextEmpty = true;
  bool _modoEmail = false;
  Timer? _debounce;
  Future<List<Map<String, dynamic>>>? _futureResultados;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final currentUserId = SessionService.userId;

    if (query.isEmpty) {
      setState(() {
        _futureResultados = null;
      });
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _futureResultados = null;
      });
      return;
    }

    setState(() {
      _futureResultados = ClienteService.buscarClientesPorNombre(
        query,
        excludeUserId: currentUserId,
      );
    });
  }

  Future<void> _mostrarDialogoEmail() async {
    final emailController = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2E2648),
        title: const Text(
          'Invitar por email',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email del cliente',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFAEA6E8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = emailController.text.trim();
              Navigator.pop(dialogContext, value.isEmpty ? null : value);
            },
            child: const Text(
              'Invitar',
              style: TextStyle(color: Color(0xFFAEA6E8)),
            ),
          ),
        ],
      ),
    );

    emailController.dispose();

    if (email == null || email.isEmpty) return;

    final currentUserId = SessionService.userId;
    final usuario = await ClienteService.buscarClientePorEmail(
      email,
      excludeUserId: currentUserId,
    );

    if (!mounted) return;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró ningún usuario con ese email'),
        ),
      );
      return;
    }

    await _invitar(usuario);
  }

  Future<void> _invitar(Map<String, dynamic> perfil) async {
    final trainerId = SessionService.userId;
    final clientId = perfil['id'] as String?;

    if (trainerId == null || clientId == null) return;

    try {
      await ClienteService.invitarCliente(
        trainerId: trainerId,
        clientId: clientId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cliente ${perfil['nombre'] ?? perfil['username'] ?? ''} añadido',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo añadir este cliente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Buscar clientes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.searchBarBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Buscar por nombre o usuario',
                            hintStyle: const TextStyle(color: Colors.white60),
                          ),
                          onChanged: (query) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 800),
                              () {
                                setState(() {
                                  _isTextEmpty = query.isEmpty;
                                });
                                _performSearch(query.trim());
                              },
                            );
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: _modoEmail
                            ? 'Volver a búsqueda por nombre'
                            : 'Invitar por email',
                        onPressed: () {
                          if (_modoEmail) {
                            setState(() {
                              _modoEmail = false;
                            });
                            _searchController.clear();
                            setState(() {
                              _futureResultados = null;
                              _isTextEmpty = true;
                            });
                          } else {
                            _mostrarDialogoEmail();
                          }
                        },
                        icon: Icon(
                          _modoEmail
                              ? Icons.person_search
                              : Icons.alternate_email,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Modo nombre activo',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildResultsList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isTextEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Escribe un nombre o email\npara empezar la búsqueda',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: _futureResultados,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentLila),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error en la búsqueda',
              style: TextStyle(color: Colors.white60),
            ),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          final resultados = snapshot.data!;

          if (resultados.isEmpty) {
            return Center(
              child: Text(
                'No se encontraron usuarios cliente',
                style: TextStyle(color: Colors.white60, fontSize: 15),
              ),
            );
          }

          return ListView.separated(
            itemCount: resultados.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final perfil = resultados[index];
              final nombre =
                  (perfil['nombre'] ?? perfil['username'] ?? 'Sin nombre')
                      as String;
              final email = (perfil['email'] ?? '') as String;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C639F),
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: TextButton(
                    onPressed: () => _invitar(perfil),
                    child: const Text('Añadir'),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }
}
