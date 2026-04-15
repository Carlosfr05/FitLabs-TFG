import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';

class DetalleRutinaScreen extends StatefulWidget {
  final String rutinaId;
  final String titulo;
  final String? descripcion;
  final String? fecha;
  final String? horaInicio;
  final String? horaFin;

  const DetalleRutinaScreen({
    super.key,
    required this.rutinaId,
    required this.titulo,
    this.descripcion,
    this.fecha,
    this.horaInicio,
    this.horaFin,
  });

  @override
  State<DetalleRutinaScreen> createState() => _DetalleRutinaScreenState();
}

class _DetalleRutinaScreenState extends State<DetalleRutinaScreen> {
  static const Color _bgTop = Color(0xFF2E2648);
  static const Color _bgBottom = Color(0xFF1A1625);
  static const Color _accentLila = Color(0xFFAEA6E8);
  static const Color _cardBg = Color(0xFF3E3666);

  List<Map<String, dynamic>> _ejerciciosRaw = [];
  Map<String, Exercise> _catalogoEjercicios = {};
  bool _cargando = true;
  bool _guardando = false;

  late TextEditingController _tituloCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _fechaCtrl;
  late TextEditingController _horaInicioCtrl;
  late TextEditingController _horaFinCtrl;
  bool _editado = false;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.titulo);
    _descripcionCtrl = TextEditingController(text: widget.descripcion ?? '');
    _fechaCtrl = TextEditingController(text: widget.fecha ?? '');
    _horaInicioCtrl = TextEditingController(text: widget.horaInicio ?? '');
    _horaFinCtrl = TextEditingController(text: widget.horaFin ?? '');
    _cargarDatos();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _fechaCtrl.dispose();
    _horaInicioCtrl.dispose();
    _horaFinCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final ejercicios = await RutinaService.fetchEjerciciosRutina(
        widget.rutinaId,
      );

      // Cargar catálogo de ejercicios del JSON local
      final jsonStr = await rootBundle.loadString('assets/json/exercises.json');
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final catalogo = <String, Exercise>{};
      for (final e in decoded) {
        final ex = Exercise.fromJson(e);
        catalogo[ex.id] = ex;
      }

      if (mounted) {
        setState(() {
          _ejerciciosRaw = ejercicios;
          _catalogoEjercicios = catalogo;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => _guardando = true);
    try {
      await RutinaService.actualizarRutina(
        rutinaId: widget.rutinaId,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        fecha: _fechaCtrl.text.trim().isEmpty ? null : _fechaCtrl.text.trim(),
        horaInicio: _horaInicioCtrl.text.trim().isEmpty
            ? null
            : _horaInicioCtrl.text.trim(),
        horaFin: _horaFinCtrl.text.trim().isEmpty
            ? null
            : _horaFinCtrl.text.trim(),
      );

      // Guardar cambios de ejercicios individuales
      for (final ej in _ejerciciosRaw) {
        await RutinaService.actualizarEjercicioRutina(
          ejercicioRutinaId: ej['id'] as String,
          series: ej['serie'] as int?,
          repeticiones: ej['repeticiones'] as int?,
          peso: (ej['peso'] as num?)?.toDouble(),
          descanso: ej['descanso'] as int?,
        );
      }

      if (mounted) {
        setState(() {
          _guardando = false;
          _editado = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina actualizada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true = hubo cambios
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCtrl.text.isNotEmpty
          ? DateTime.tryParse(_fechaCtrl.text) ?? now
          : now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accentLila,
            surface: _bgTop,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _fechaCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _editado = true);
    }
  }

  Future<void> _seleccionarHora(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: parts.length == 2 ? int.tryParse(parts[0]) ?? 9 : 9,
      minute: parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accentLila,
            surface: _bgTop,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _editado = true);
    }
  }

  void _editarEjercicio(int index) {
    final ej = _ejerciciosRaw[index];
    final serieCtrl = TextEditingController(text: '${ej['serie'] ?? 1}');
    final repsCtrl = TextEditingController(text: '${ej['repeticiones'] ?? ''}');
    final pesoCtrl = TextEditingController(
      text: ej['peso'] != null ? '${ej['peso']}' : '',
    );
    final descansoCtrl = TextEditingController(text: '${ej['descanso'] ?? ''}');

    final exId = ej['id_ejercicio_externo'] as String? ?? '';
    final exInfo = _catalogoEjercicios[exId];

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
            Text(
              exInfo?.name ?? 'Ejercicio',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildEditField(serieCtrl, 'Series', Icons.repeat),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditField(
                    repsCtrl,
                    'Repeticiones',
                    Icons.format_list_numbered,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEditField(
                    pesoCtrl,
                    'Peso (kg)',
                    Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditField(
                    descansoCtrl,
                    'Descanso (s)',
                    Icons.timer,
                  ),
                ),
              ],
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
                onPressed: () {
                  setState(() {
                    _ejerciciosRaw[index] = {
                      ..._ejerciciosRaw[index],
                      'serie': int.tryParse(serieCtrl.text) ?? 1,
                      'repeticiones': int.tryParse(repsCtrl.text),
                      'peso': double.tryParse(pesoCtrl.text),
                      'descanso': int.tryParse(descansoCtrl.text),
                    };
                    _editado = true;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Aplicar cambios',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    TextEditingController ctrl,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: _accentLila, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, Color(0xFF241E32), _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- BARRA SUPERIOR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Detalle de Rutina',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_editado)
                      _guardando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: _accentLila,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.save_rounded,
                                color: _accentLila,
                                size: 26,
                              ),
                              onPressed: _guardarCambios,
                            ),
                  ],
                ),
              ),

              // --- CONTENIDO ---
              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(color: _accentLila),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // --- INFO EDITABLE ---
                            _buildInfoSection(),

                            const SizedBox(height: 24),

                            // --- LISTA DE EJERCICIOS ---
                            Row(
                              children: [
                                const Icon(
                                  Icons.fitness_center,
                                  color: _accentLila,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ejercicios (${_ejerciciosRaw.length})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...List.generate(_ejerciciosRaw.length, (i) {
                              return _buildEjercicioCard(i);
                            }),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          TextField(
            controller: _tituloCtrl,
            onChanged: (_) => setState(() => _editado = true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: 'Título de la rutina',
              hintStyle: TextStyle(color: Colors.white30),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 10),

          // Descripción
          TextField(
            controller: _descripcionCtrl,
            onChanged: (_) => setState(() => _editado = true),
            maxLines: 2,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Añadir descripción...',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const Divider(color: Colors.white12, height: 24),

          // Fecha y hora
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.calendar_today,
                  label: _fechaCtrl.text.isNotEmpty
                      ? _fechaCtrl.text
                      : 'Sin fecha',
                  onTap: _seleccionarFecha,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.schedule,
                  label: _horaInicioCtrl.text.isNotEmpty
                      ? '${_horaInicioCtrl.text}${_horaFinCtrl.text.isNotEmpty ? ' - ${_horaFinCtrl.text}' : ''}'
                      : 'Sin hora',
                  onTap: () => _seleccionarHora(_horaInicioCtrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accentLila, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.edit, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildEjercicioCard(int index) {
    final ej = _ejerciciosRaw[index];
    final exId = ej['id_ejercicio_externo'] as String? ?? '';
    final exInfo = _catalogoEjercicios[exId];
    final nombre = exInfo?.name ?? exId;
    final series = ej['serie'] as int? ?? 1;
    final reps = ej['repeticiones'] as int?;
    final peso = ej['peso'];
    final descanso = ej['descanso'] as int?;
    final imageUrl = exInfo?.thumbnailImageUrl;

    return GestureDetector(
      onTap: () => _editarEjercicio(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Imagen del ejercicio
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 56,
                height: 56,
                color: const Color(0xFF4B4584),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.fitness_center,
                            color: Colors.white38,
                            size: 24,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.white38,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag('$series series'),
                      if (reps != null) _buildTag('$reps reps'),
                      if (peso != null) _buildTag('${peso}kg'),
                      if (descanso != null) _buildTag('${descanso}s desc.'),
                    ],
                  ),
                  if (exInfo != null && exInfo.primaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      exInfo.primaryMuscles.join(', '),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Icono editar
            const Icon(Icons.edit_outlined, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _accentLila.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _accentLila,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
