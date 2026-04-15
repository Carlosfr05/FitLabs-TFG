import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/data/chat_service.dart';
import 'package:pantallas_fitlabs/data/message_notification_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _mensajes = [];
  bool _cargando = true;
  bool _enviandoMedia = false;
  RealtimeChannel? _channel;
  Timer? _pollTimer;
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _grabandoAudio = false;
  String? _audioPlaying;

  String get _myId => SessionService.userId!;

  @override
  void initState() {
    super.initState();
    MessageNotificationService.instance.setActiveChat(widget.chatId);
    _cargarMensajes();
    _suscribirse();
    // Polling cada 5s como fallback si Realtime falla
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refrescarMensajes();
    });
  }

  @override
  void dispose() {
    MessageNotificationService.instance.setActiveChat(null);
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _recorder.dispose();
    if (_channel != null) {
      ChatService.cancelarSuscripcion(_channel!);
    }
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    final data = await ChatService.fetchMensajes(widget.chatId);
    if (!mounted) return;
    setState(() {
      _mensajes = data;
      _cargando = false;
    });
    _scrollToBottom();
    // Marcar como leídos
    ChatService.marcarComoLeido(widget.chatId, _myId);
  }

  Future<void> _refrescarMensajes() async {
    final data = await ChatService.fetchMensajes(widget.chatId);
    if (!mounted) return;
    // Contar mensajes reales (sin temporales)
    final realCount = _mensajes
        .where((m) => !(m['id']?.toString().startsWith('temp-') ?? false))
        .length;
    if (data.length > realCount) {
      setState(() => _mensajes = data);
      _scrollToBottom();
      ChatService.marcarComoLeido(widget.chatId, _myId);
    }
  }

  void _suscribirse() {
    _channel = ChatService.suscribirseAMensajes(widget.chatId, (nuevo) {
      if (!mounted) return;
      setState(() {
        _mensajes.add(nuevo);
      });
      _scrollToBottom();
      // Si el mensaje es del otro, marcar como leído
      if (nuevo['id_remitente'] != _myId) {
        ChatService.marcarComoLeido(widget.chatId, _myId);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    _controller.clear();

    // Optimistic update: mostrar al instante
    final msgLocal = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'id_chat': widget.chatId,
      'id_remitente': _myId,
      'contenido': texto,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'leido': false,
    };
    setState(() => _mensajes.add(msgLocal));
    _scrollToBottom();

    await ChatService.enviarMensaje(widget.chatId, _myId, texto);
  }

  void _mostrarOpcionesAdjuntar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _opcionAdjuntar(Icons.photo_library_rounded, 'Galería', () {
                Navigator.pop(context);
                _enviarFoto(ImageSource.gallery);
              }),
              _opcionAdjuntar(Icons.camera_alt_rounded, 'Cámara', () {
                Navigator.pop(context);
                _enviarFoto(ImageSource.camera);
              }),
              _opcionAdjuntar(Icons.videocam_rounded, 'Vídeo', () {
                Navigator.pop(context);
                _enviarVideo();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcionAdjuntar(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentLila.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accentLila, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.textColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarFoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked == null) return;
    setState(() => _enviandoMedia = true);
    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      await ChatService.enviarMensajeMultimedia(
        chatId: widget.chatId,
        senderId: _myId,
        tipoContenido: 'imagen',
        archivo: file,
        extension: ext,
      );
      await _refrescarMensajes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar imagen: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoMedia = false);
    }
  }

  Future<void> _enviarVideo() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (picked == null) return;
    setState(() => _enviandoMedia = true);
    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      await ChatService.enviarMensajeMultimedia(
        chatId: widget.chatId,
        senderId: _myId,
        tipoContenido: 'video',
        archivo: file,
        extension: ext,
      );
      await _refrescarMensajes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar vídeo: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoMedia = false);
    }
  }

  Future<void> _toggleAudio(String url) async {
    if (_audioPlaying == url) {
      await _audioPlayer.stop();
      setState(() => _audioPlaying = null);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _audioPlaying = url);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _audioPlaying = null);
      });
    }
  }

  Future<void> _iniciarGrabacion() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() => _grabandoAudio = true);
    }
  }

  Future<void> _pararYEnviarGrabacion() async {
    final path = await _recorder.stop();
    setState(() => _grabandoAudio = false);
    if (path == null) return;
    setState(() => _enviandoMedia = true);
    try {
      final file = File(path);
      await ChatService.enviarMensajeMultimedia(
        chatId: widget.chatId,
        senderId: _myId,
        tipoContenido: 'audio',
        archivo: file,
        extension: 'm4a',
      );
      await _refrescarMensajes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar audio: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoMedia = false);
    }
  }

  String _formatHora(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.tryParse(timestamp)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white70),
                      )
                    : _mensajes.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin mensajes aún.\n¡Envía el primero!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          return _buildBubble(_mensajes[index]);
                        },
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.cardBg,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['id_remitente'] == _myId;
    final tipo = msg['tipo_contenido']?.toString() ?? 'texto';
    final mediaUrl = msg['media_url']?.toString();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: tipo == 'imagen'
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6C639F) : AppColors.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Contenido multimedia
            if (tipo == 'imagen' && mediaUrl != null)
              GestureDetector(
                onTap: () => _mostrarImagenCompleta(mediaUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    mediaUrl,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 220,
                        height: 220,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          color: AppColors.accentLila,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      width: 220,
                      height: 100,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              )
            else if (tipo == 'video' && mediaUrl != null)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reproductor de vídeo próximamente'),
                    ),
                  );
                },
                child: Container(
                  width: 220,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Vídeo',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else if (tipo == 'audio' && mediaUrl != null)
              GestureDetector(
                onTap: () => _toggleAudio(mediaUrl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _audioPlaying == mediaUrl
                          ? Icons.stop_circle
                          : Icons.play_circle_fill,
                      color: AppColors.accentLila,
                      size: 36,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _audioPlaying == mediaUrl ? 'Reproduciendo...' : 'Audio',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              Text(
                msg['contenido'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: tipo == 'imagen'
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                  : EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatHora(msg['creado_en']?.toString()),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg['leido'] == true ? Icons.done_all : Icons.done,
                      size: 14,
                      color: msg['leido'] == true
                          ? Colors.lightBlueAccent
                          : Colors.white54,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarImagenCompleta(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: AppColors.navBarBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_enviandoMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentLila,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Enviando archivo...',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: _enviandoMedia ? null : _mostrarOpcionesAdjuntar,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentLila.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    color: _enviandoMedia
                        ? Colors.white24
                        : AppColors.accentLila,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_grabandoAudio)
                GestureDetector(
                  onTap: _pararYEnviarGrabacion,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stop,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                )
              else ...[
                GestureDetector(
                  onTap: _iniciarGrabacion,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentLila.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: AppColors.accentLila,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _enviarMensaje,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C639F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
