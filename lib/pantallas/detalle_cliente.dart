import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/shared_widgets.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/data/progreso_service.dart';
import 'package:pantallas_fitlabs/pantallas/seguimiento_live_screen.dart';
import 'package:pantallas_fitlabs/pantallas/stats_cliente_screen.dart';
import 'package:pantallas_fitlabs/pantallas/detalle_rutina_screen.dart';
import 'package:pantallas_fitlabs/pantallas/chat_screen.dart';
import 'package:pantallas_fitlabs/pantallas/crear_rutina.dart';
import 'package:pantallas_fitlabs/data/chat_service.dart';
import 'package:pantallas_fitlabs/data/cliente_service.dart';

class DetalleClienteScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const DetalleClienteScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends State<DetalleClienteScreen> {
  // --- PALETA DE COLORES ---
  final Color _bgTop = const Color(0xFF2E2648);
  final Color _bgBottom = const Color(0xFF1A1625);
  final Color _accentLila = const Color(0xFFAEA6E8);
  final Color _cardSummaryBg = const Color(0xFF3E3666);
  final Color _cardGraphBg = const Color(0xFF2B253F);

  List<Map<String, dynamic>> _rutinas = [];
  List<Map<String, dynamic>> _historial = [];
  int _sesionesCompletadas = 0;
  int _rachaSemanal = 0;
  double _cumplimiento = 0;
  double _volumenSemanal = 0;
  String? _avatarUrl;
  String? _objetivo;
  String? _bio;
  bool _tieneSesionActiva = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final results = await Future.wait<dynamic>([
        RutinaService.fetchRutinasDeCliente(
          SessionService.userId!,
          widget.clientId,
        ),
        ProgresoService.fetchHistorialCliente(widget.clientId),
        ProgresoService.contarSesionesCompletadas(widget.clientId),
        ProgresoService.calcularRachaSemanal(widget.clientId),
        ProgresoService.calcularCumplimiento(widget.clientId),
        ProgresoService.calcularVolumenSemanal(widget.clientId),
        Supabase.instance.client
            .from('perfiles')
            .select('avatar_url, bio, objetivo')
            .eq('id', widget.clientId)
            .maybeSingle(),
      ]);

      final rutinas = results[0] as List<Map<String, dynamic>>;

      // Comprobar si tiene sesión activa
      bool hayActiva = false;
      for (final r in rutinas) {
        final s = await ProgresoService.fetchSesionActiva(
          r['id'] as String,
          widget.clientId,
        );
        if (s != null) {
          hayActiva = true;
          break;
        }
      }

      final perfil = results[6] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _rutinas = rutinas;
          _historial = results[1] as List<Map<String, dynamic>>;
          _sesionesCompletadas = results[2] as int;
          _rachaSemanal = results[3] as int;
          _cumplimiento = results[4] as double;
          _volumenSemanal = results[5] as double;
          _avatarUrl = perfil?['avatar_url'] as String?;
          _objetivo = perfil?['objetivo'] as String?;
          _bio = perfil?['bio'] as String?;
          _tieneSesionActiva = hayActiva;
        });
      }
    } catch (_) {
      // Silenciar
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, const Color(0xFF241E32), _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- CABECERA MODERNA ---
                _buildModernHeader(context),

                const SizedBox(height: 25),

                // --- CONTENIDO PRINCIPAL ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de Stats
                      _buildSummaryCard(),

                      const SizedBox(height: 16),

                      // --- BOTONES DE ACCIÓN ---
                      _buildActionButtons(),

                      const SizedBox(height: 24),

                      // --- RENDIMIENTO ACTUAL ---
                      _buildRendimientoCard(),

                      const SizedBox(height: 30),

                      // --- SESIONES COMPLETADAS ---
                      const Text(
                        "Sesiones Completadas",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_historial.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.white24,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sin sesiones completadas a\u00fan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List.generate(
                          _historial.length > 5 ? 5 : _historial.length,
                          (i) {
                            final s = _historial[i];
                            final rutina = s['rutina'] as Map<String, dynamic>?;
                            final titulo =
                                rutina?['title'] as String? ?? 'Rutina';
                            final fecha = s['fecha'] as String? ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E4A3E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade700,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade400,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titulo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          fecha,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (s['notas'] != null)
                                    const Icon(
                                      Icons.note,
                                      color: Colors.white38,
                                      size: 18,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 30),

                      // --- SESIONES / RUTINAS ASIGNADAS ---
                      const Text(
                        "Rutinas Asignadas",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Lista de rutinas reales
                      if (_cargando)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Color(0xFFAEA6E8),
                            ),
                          ),
                        )
                      else if (_rutinas.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Sin rutinas asignadas aún',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ...List.generate(_rutinas.length, (i) {
                          final r = _rutinas[i];
                          final fecha = r['fecha'] as String?;
                          final hora = r['hora_inicio'] as String?;
                          final sub = [?fecha, ?hora].join(' · ');
                          return GestureDetector(
                            onTap: () async {
                              final cambio = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleRutinaScreen(
                                    rutinaId: r['id'] as String,
                                    titulo:
                                        r['title'] as String? ?? 'Sin título',
                                    descripcion: r['description'] as String?,
                                    fecha: r['fecha'] as String?,
                                    horaInicio: r['hora_inicio'] as String?,
                                    horaFin: r['hora_fin'] as String?,
                                  ),
                                ),
                              );
                              if (cambio == true) _cargarDatos();
                            },
                            child: _buildSessionItem(
                              title: r['title'] as String? ?? 'Sin título',
                              dateOrTime: sub.isNotEmpty ? sub : 'Sin fecha',
                              isLast: i == _rutinas.length - 1,
                            ),
                          );
                        }),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MENÚ DE ACCIONES
  // --------------------------------------------------------------------------

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? Colors.redAccent : Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? Colors.redAccent : Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'editar':
        _mostrarEditarPerfil();
        break;
      case 'rutina':
        _asignarRutina();
        break;
      case 'mensaje':
        _enviarMensaje();
        break;
      case 'historial':
        _verHistorialCompleto();
        break;
      case 'eliminar':
        _confirmarEliminar();
        break;
    }
  }

  // --- EDITAR PERFIL ---
  void _mostrarEditarPerfil() {
    final objetivoCtrl = TextEditingController(text: _objetivo ?? '');
    final bioCtrl = TextEditingController(text: _bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Editar Perfil del Cliente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: objetivoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Objetivo principal',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(
                  Icons.flag,
                  color: Color(0xFFAEA6E8),
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Biografía / notas',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(
                  Icons.notes,
                  color: Color(0xFFAEA6E8),
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentLila,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final data = <String, dynamic>{};
                    final obj = objetivoCtrl.text.trim();
                    final bio = bioCtrl.text.trim();
                    if (obj.isNotEmpty) data['objetivo'] = obj;
                    if (bio.isNotEmpty) data['bio'] = bio;
                    if (data.isNotEmpty) {
                      await Supabase.instance.client
                          .from('perfiles')
                          .update(data)
                          .eq('id', widget.clientId);
                    }
                    _cargarDatos();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perfil actualizado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ASIGNAR RUTINA ---
  void _asignarRutina() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearRutinaScreen()),
    ).then((_) => _cargarDatos());
  }

  // --- ENVIAR MENSAJE ---
  Future<void> _enviarMensaje() async {
    try {
      final chatId = await ChatService.getOrCreateChat(
        SessionService.userId!,
        widget.clientId,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: widget.clientName,
            otherUserAvatar: _avatarUrl,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- HISTORIAL COMPLETO ---
  void _verHistorialCompleto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFFAEA6E8), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Historial completo (${_historial.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _historial.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin sesiones completadas',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _historial.length,
                      itemBuilder: (_, i) {
                        final s = _historial[i];
                        final rutina = s['rutina'] as Map<String, dynamic>?;
                        final titulo = rutina?['title'] as String? ?? 'Rutina';
                        final fecha = s['fecha'] as String? ?? '';
                        final notas = s['notas'] as String?;
                        final finalizada = s['finalizada'] as bool? ?? true;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: finalizada
                                ? const Color(0xFF2E4A3E)
                                : const Color(0xFF4A3E2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: finalizada
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    finalizada
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    color: finalizada
                                        ? Colors.green.shade400
                                        : Colors.orange.shade400,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      titulo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    fecha,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (notas != null && notas.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.format_quote,
                                        color: Colors.white30,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          notas,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ELIMINAR CLIENTE ---
  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3E3666),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar cliente?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se eliminará la relación con ${widget.clientName}. Las rutinas y sesiones se mantendrán.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Buscar la relación
                final relacion = await Supabase.instance.client
                    .from('clientes_entrenador')
                    .select('id')
                    .eq('trainer_id', SessionService.userId!)
                    .eq('client_id', widget.clientId)
                    .maybeSingle();

                if (relacion != null) {
                  await ClienteService.eliminarCliente(
                    relacion['id'] as String,
                  );
                }
                if (mounted) {
                  Navigator.pop(context); // Volver a mis clientes
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGETS
  // --------------------------------------------------------------------------

  // *** HEADER MODERNO (El que te gustó) ***
  Widget _buildModernHeader(BuildContext context) {
    return Column(
      children: [
        // 1. Barra superior
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Perfil de Cliente",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 26,
                ),
                color: const Color(0xFF3E3666),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: _onMenuAction,
                itemBuilder: (_) => [
                  _buildPopupItem(
                    'editar',
                    Icons.edit_outlined,
                    'Editar perfil',
                  ),
                  _buildPopupItem('rutina', Icons.add_chart, 'Asignar rutina'),
                  _buildPopupItem(
                    'mensaje',
                    Icons.chat_bubble_outline,
                    'Enviar mensaje',
                  ),
                  _buildPopupItem(
                    'historial',
                    Icons.history,
                    'Historial completo',
                  ),
                  const PopupMenuDivider(),
                  _buildPopupItem(
                    'eliminar',
                    Icons.person_remove,
                    'Eliminar cliente',
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Avatar Grande
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _tieneSesionActiva
                      ? Colors.greenAccent.withValues(alpha: 0.7)
                      : _accentLila.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF4B4584),
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null || _avatarUrl!.isEmpty
                    ? Text(
                        widget.clientName.isNotEmpty
                            ? widget.clientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            if (_tieneSesionActiva)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bgTop, width: 3),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 15),

        // 3. Info Cliente
        Text(
          widget.clientName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _accentLila.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentLila.withValues(alpha: 0.5)),
          ),
          child: Text(
            "Cliente Activo",
            style: TextStyle(
              color: _accentLila,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 4. Caja de Objetivo (dinámico)
        if (_objetivo != null && _objetivo!.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "OBJETIVO PRINCIPAL",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _objetivo!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          )
        else if (_bio != null && _bio!.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: _cardSummaryBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('${_rutinas.length}', "Rutinas"),
          Container(width: 1, height: 35, color: Colors.white12),
          _buildSummaryItem('$_sesionesCompletadas', "Completadas"),
          Container(width: 1, height: 35, color: Colors.white12),
          _buildSummaryItem(
            _rutinas.where((r) => r['fecha'] != null).length.toString(),
            "Programadas",
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String value,
    String label, {
    bool isBoldValue = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _abrirSeguimientoLive,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _tieneSesionActiva
                    ? Colors.greenAccent.withValues(alpha: 0.25)
                    : Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _tieneSesionActiva
                      ? Colors.greenAccent.withValues(alpha: 0.7)
                      : Colors.greenAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Colors.greenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'En vivo',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_tieneSesionActiva) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsClienteScreen(
                    clientId: widget.clientId,
                    clienteNombre: widget.clientName,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _accentLila.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentLila.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, color: _accentLila, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Estadísticas',
                    style: TextStyle(
                      color: _accentLila,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRendimientoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardGraphBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rendimiento Actual',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRendimientoItem(
                  icon: Icons.local_fire_department,
                  color: Colors.orangeAccent,
                  valor: '$_rachaSemanal',
                  label: 'Racha\nsemanal',
                ),
              ),
              Expanded(
                child: _buildRendimientoItem(
                  icon: Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  valor: '${_cumplimiento.toStringAsFixed(0)}%',
                  label: 'Cumplimiento',
                ),
              ),
              Expanded(
                child: _buildRendimientoItem(
                  icon: Icons.fitness_center,
                  color: _accentLila,
                  valor: _volumenSemanal >= 1000
                      ? '${(_volumenSemanal / 1000).toStringAsFixed(1)}k'
                      : _volumenSemanal.toStringAsFixed(0),
                  label: 'Vol. semanal\n(kg)',
                ),
              ),
              Expanded(
                child: _buildRendimientoItem(
                  icon: Icons.emoji_events,
                  color: Colors.amberAccent,
                  valor: '$_sesionesCompletadas',
                  label: 'Sesiones\ntotales',
                ),
              ),
            ],
          ),
          if (_tieneSesionActiva) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sesión en curso ahora mismo',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRendimientoItem({
    required IconData icon,
    required Color color,
    required String valor,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _abrirSeguimientoLive() async {
    // Buscar sesión activa del cliente en alguna rutina de hoy
    String? sesionActiva;
    String? rutinaActiva;

    for (final rutina in _rutinas) {
      final id = rutina['id'] as String;
      final sesion = await ProgresoService.fetchSesionActiva(
        id,
        widget.clientId,
      );
      if (sesion != null) {
        sesionActiva = sesion;
        rutinaActiva = id;
        break;
      }
    }

    if (!mounted) return;

    if (sesionActiva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El cliente no tiene una sesión activa ahora'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeguimientoLiveScreen(
          sesionId: sesionActiva!,
          rutinaId: rutinaActiva!,
          clienteNombre: widget.clientName,
        ),
      ),
    );
  }

  Widget _buildSessionItem({
    required String title,
    required String dateOrTime,
    required bool isLast,
  }) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFD5D0FF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        dateOrTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: const DashedDivider(),
          ),
      ],
    );
  }
}
