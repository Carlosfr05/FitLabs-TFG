import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';
import 'package:pantallas_fitlabs/data/progreso_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';

/// Pantalla donde el cliente marca ejercicios completados y registra peso/reps reales.
class CompletarRutinaScreen extends StatefulWidget {
  final String rutinaId;
  final String rutinaTitle;

  const CompletarRutinaScreen({
    super.key,
    required this.rutinaId,
    required this.rutinaTitle,
  });

  @override
  State<CompletarRutinaScreen> createState() => _CompletarRutinaScreenState();
}

class _CompletarRutinaScreenState extends State<CompletarRutinaScreen> {
  List<Map<String, dynamic>> _ejercicios = [];
  bool _cargando = true;
  bool _guardando = false;
  String? _sesionId; // Se crea al abrir la pantalla
  final TextEditingController _notasController = TextEditingController();

  // Estado de completado por ejercicio
  // Key = id del ejercicio_rutina, Value = {completado, pesoReal, repsReal}
  final Map<String, _EjercicioState> _estado = {};

  @override
  void initState() {
    super.initState();
    _iniciarSesion();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  /// Crea (o recupera) la sesión y carga los ejercicios.
  Future<void> _iniciarSesion() async {
    try {
      final clientId = SessionService.userId!;

      // ¿Ya hay sesión activa de hoy para esta rutina?
      _sesionId = await ProgresoService.fetchSesionActiva(
        widget.rutinaId,
        clientId,
      );

      // Si no existe, crear sesión nueva
      _sesionId ??= await ProgresoService.crearSesion(
        rutinaId: widget.rutinaId,
        clientId: clientId,
      );

      // Cargar ejercicios de la rutina
      final data = await RutinaService.fetchEjerciciosRutina(widget.rutinaId);

      // Restaurar estado si la sesión ya tenía ejercicios marcados
      final completados =
          await ProgresoService.fetchEjerciciosCompletadosDeSesion(_sesionId!);
      final Map<String, Map<String, dynamic>> completadosMap = {};
      for (final c in completados) {
        completadosMap[c['id_ejercicio_rutina'] as String] = c;
      }

      if (!mounted) return;
      setState(() {
        _ejercicios = data;
        for (final ej in data) {
          final id = ej['id'] as String;
          final prev = completadosMap[id];
          _estado[id] = _EjercicioState(
            completado: prev?['completado'] == true,
            pesoReal: prev != null
                ? (prev['peso_real'] as num?)?.toDouble()
                : (ej['peso'] as num?)?.toDouble(),
            repsReal: prev != null
                ? (prev['reps_real'] as num?)?.toInt()
                : ej['repeticiones'] as int?,
          );
        }
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Guarda un ejercicio individual en la BD (llamado al marcar/desmarcar).
  Future<void> _guardarEjercicio(String idEjercicioRutina) async {
    if (_sesionId == null) return;
    final estado = _estado[idEjercicioRutina];
    if (estado == null) return;

    try {
      await ProgresoService.upsertEjercicioCompletado(
        sesionId: _sesionId!,
        idEjercicioRutina: idEjercicioRutina,
        completado: estado.completado,
        pesoReal: estado.pesoReal,
        repsReal: estado.repsReal,
      );
    } catch (_) {
      // Silencioso: se reintentará al finalizar
    }
  }

  /// Finaliza la sesión.
  Future<void> _finalizarSesion() async {
    if (_sesionId == null) return;
    setState(() => _guardando = true);
    try {
      // Guardar todos los ejercicios por si alguno falló
      for (final entry in _estado.entries) {
        await ProgresoService.upsertEjercicioCompletado(
          sesionId: _sesionId!,
          idEjercicioRutina: entry.key,
          completado: entry.value.completado,
          pesoReal: entry.value.pesoReal,
          repsReal: entry.value.repsReal,
        );
      }

      await ProgresoService.finalizarSesion(
        _sesionId!,
        _notasController.text.trim().isNotEmpty
            ? _notasController.text.trim()
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Sesión finalizada! 💪'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  int get _completados => _estado.values.where((e) => e.completado).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (_cargando)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    children: [
                      // Progreso
                      _buildProgressHeader(),
                      const SizedBox(height: 20),

                      // Lista de ejercicios
                      ..._ejercicios.map((ej) => _buildEjercicioTile(ej)),

                      const SizedBox(height: 20),

                      // Notas
                      _buildNotasField(),

                      const SizedBox(height: 24),

                      // Botón guardar
                      _buildGuardarButton(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.rutinaTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Registrar sesión',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final total = _ejercicios.length;
    final pct = total > 0 ? _completados / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_completados / $total ejercicios',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.accentLila,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentLila,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEjercicioTile(Map<String, dynamic> ej) {
    final id = ej['id'] as String;
    final estado = _estado[id]!;
    final nombre = ej['id_ejercicio_externo'] as String? ?? 'Ejercicio';
    final series = ej['serie'] as int? ?? 1;
    final reps = ej['repeticiones'] as int?;
    final peso = (ej['peso'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: estado.completado ? const Color(0xFF2E4A3E) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: estado.completado
            ? Border.all(color: Colors.green.shade400, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: checkbox + nombre
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    estado.completado = !estado.completado;
                  });
                  _guardarEjercicio(id);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: estado.completado
                        ? Colors.green.shade400
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: estado.completado
                          ? Colors.green.shade400
                          : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: estado.completado
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: estado.completado
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white54,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Info programada
          Text(
            '${series}x${reps ?? '—'} reps · ${peso != null ? '${peso}kg' : 'Sin peso'}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),

          // Inputs de peso y reps reales (solo si está marcado)
          if (estado.completado) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniInput(
                    label: 'Peso real (kg)',
                    initial: estado.pesoReal?.toString() ?? '',
                    onChanged: (val) {
                      estado.pesoReal = double.tryParse(val);
                      _guardarEjercicio(id);
                    },
                    isDecimal: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniInput(
                    label: 'Reps reales',
                    initial: estado.repsReal?.toString() ?? '',
                    onChanged: (val) {
                      estado.repsReal = int.tryParse(val);
                      _guardarEjercicio(id);
                    },
                    isDecimal: false,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniInput({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    required bool isDecimal,
  }) {
    return TextField(
      controller: TextEditingController(text: initial),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentLila),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildNotasField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas (opcional)',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notasController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '¿Cómo te has sentido? ¿Algo que destacar?',
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            filled: true,
            fillColor: AppColors.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuardarButton() {
    return GestureDetector(
      onTap: _guardando ? null : _finalizarSesion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _completados > 0
              ? Colors.green.shade600
              : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _guardando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _completados > 0
                      ? 'Finalizar sesión ($_completados/${_ejercicios.length})'
                      : 'Marca al menos un ejercicio',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

class _EjercicioState {
  bool completado;
  double? pesoReal;
  int? repsReal;

  _EjercicioState({required this.completado, this.pesoReal, this.repsReal});
}
