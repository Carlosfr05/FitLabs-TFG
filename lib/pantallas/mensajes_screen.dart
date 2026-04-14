import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/data/chat_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/data/cliente_service.dart';
import 'package:pantallas_fitlabs/pantallas/chat_screen.dart';

class MensajesScreen extends StatefulWidget {
  const MensajesScreen({super.key});

  @override
  State<MensajesScreen> createState() => _MensajesScreenState();
}

class _MensajesScreenState extends State<MensajesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _chats = [];
  bool _cargando = true;
  RealtimeChannel? _channel;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _cargarChats();
    _suscribirse();
    // Polling cada 5s como fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cargarChats();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    if (_channel != null) {
      ChatService.cancelarSuscripcion(_channel!);
    }
    super.dispose();
  }

  Future<void> _cargarChats() async {
    final userId = SessionService.userId;
    if (userId == null) return;
    final data = await ChatService.fetchChats(userId);
    if (!mounted) return;
    setState(() {
      _chats = data;
      _cargando = false;
    });
  }

  void _suscribirse() {
    final userId = SessionService.userId;
    if (userId == null) return;
    _channel = ChatService.suscribirseAChats(userId, () {
      _cargarChats();
    });
  }

  void _abrirChat(Map<String, dynamic> chat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat['chatId'],
          otherUserName: chat['nombre'],
          otherUserAvatar: chat['avatarUrl'],
        ),
      ),
    );
    // Al volver, recargar chats para actualizar contadores
    _cargarChats();
  }

  void _mostrarNuevoChat() async {
    final userId = SessionService.userId;
    if (userId == null) return;

    // Obtener la lista de contactos (mis clientes si soy entrenador, o mis entrenadores)
    List<Map<String, dynamic>> contactos = [];
    if (SessionService.isEntrenador) {
      final clientes = await ClienteService.fetchMisClientes(userId);
      for (final rel in clientes) {
        final perfil = rel['perfiles'] ?? rel['client'];
        if (perfil != null) {
          contactos.add({
            'id': perfil['id'],
            'nombre': perfil['nombre'] ?? perfil['username'] ?? 'Usuario',
          });
        }
      }
    } else {
      // Cliente: buscar mis entrenadores
      final rels = await Supabase.instance.client
          .from('clientes_entrenador')
          .select('trainer_id, perfiles!trainer_id(id, username, nombre)')
          .eq('client_id', userId)
          .eq('status', 'aceptado');
      for (final rel in rels) {
        final perfil = rel['perfiles'];
        if (perfil != null) {
          contactos.add({
            'id': perfil['id'],
            'nombre': perfil['nombre'] ?? perfil['username'] ?? 'Usuario',
          });
        }
      }
    }

    if (!mounted) return;
    if (contactos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes contactos disponibles')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nueva conversación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...contactos.map((c) {
                final initial = (c['nombre'] as String).isNotEmpty
                    ? (c['nombre'] as String)[0].toUpperCase()
                    : '?';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C639F),
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    c['nombre'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final chatId = await ChatService.getOrCreateChat(
                      userId,
                      c['id'],
                    );
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chatId,
                          otherUserName: c['nombre'],
                        ),
                      ),
                    );
                    _cargarChats();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.tryParse(timestamp)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return dias[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const searchBarColor = Color(0xFF463C6E);
    const cardColor = Color(0xFF2E2744);
    const accentRed = Color(0xFFFF3B30);

    final navIndex = SessionService.isEntrenador ? 3 : 2;

    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          AppBottomNavBar.handleHorizontalSwipe(context, navIndex, details);
        },
        child: AppBackground(
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
                  child: _cargando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarChats,
                          child: Builder(
                            builder: (context) {
                              final filtered = _searchQuery.isEmpty
                                  ? _chats
                                  : _chats
                                        .where(
                                          (c) => (c['nombre'] as String)
                                              .toLowerCase()
                                              .contains(
                                                _searchQuery.toLowerCase(),
                                              ),
                                        )
                                        .toList();

                              if (filtered.isEmpty) {
                                return ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.white24,
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Center(
                                      child: Text(
                                        'Sin conversaciones',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  20,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final chat = filtered[index];
                                  return _buildChatCard(
                                    chat,
                                    cardColor,
                                    accentRed,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),

      // FAB — Nuevo chat
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: GestureDetector(
          onTap: _mostrarNuevoChat,
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
      bottomNavigationBar: AppBottomNavBar(currentIndex: navIndex),
    );
  }

  Widget _buildChatCard(
    Map<String, dynamic> chat,
    Color cardColor,
    Color accentRed,
  ) {
    final nombre = chat['nombre'] as String;
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final unread = chat['unreadCount'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _abrirChat(chat),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF6C639F),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: unread > 0
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMessage'] ?? '',
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
                  _formatTime(chat['lastMessageTime']?.toString()),
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 5),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread.toString(),
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
      ),
    );
  }
}
