import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/data/cliente_service.dart';
import 'package:pantallas_fitlabs/data/rutina_service.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';
import 'package:pantallas_fitlabs/pantallas/exercise_config_screen.dart';

class CrearRutinaScreen extends StatefulWidget {
  final DateTime? initialDate;
  const CrearRutinaScreen({super.key, this.initialDate});

  @override
  State<CrearRutinaScreen> createState() => _CrearRutinaScreenState();
}

class _CrearRutinaScreenState extends State<CrearRutinaScreen> {
  List<ConfiguredExercise> listaEjerciciosConfigurados = [];
  final TextEditingController _tituloController = TextEditingController(
    text: "",
  );
  final TextEditingController _comentarioGeneralController =
      TextEditingController();

  // Cliente seleccionado y lista de clientes
  List<Map<String, dynamic>> _clientes = [];
  String? _clienteSeleccionadoId;
  String _clienteSeleccionadoNombre = 'Sin asignar';

  // Fecha y hora
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.initialDate;
    _cargarClientes();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _comentarioGeneralController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    if (!SessionService.isEntrenador) return;
    try {
      final data = await ClienteService.fetchMisClientes(
        SessionService.userId!,
      );
      if (mounted) setState(() => _clientes = data);
    } catch (_) {}
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  Future<void> _seleccionarHora({required bool esInicio}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esInicio
          ? (_horaInicio ?? TimeOfDay.now())
          : (_horaFin ?? TimeOfDay.now()),
    );
    if (picked != null && mounted) {
      setState(() {
        if (esInicio) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  Future<void> _guardarRutina() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un título para la rutina')),
      );
      return;
    }
    if (listaEjerciciosConfigurados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un ejercicio')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final ejerciciosData = listaEjerciciosConfigurados.map((ce) {
        final primerSet = ce.sets.isNotEmpty ? ce.sets.first : null;
        return {
          'exerciseId': ce.exercise.id,
          'series': ce.sets.length,
          'reps': primerSet?.reps != null
              ? int.tryParse(primerSet!.reps!)
              : null,
          'weight': primerSet?.weight,
          'duration': primerSet?.duration != null
              ? int.tryParse(primerSet!.duration!)
              : null,
          'rest': primerSet?.restTime != null
              ? int.tryParse(primerSet!.restTime!)
              : null,
        };
      }).toList();

      String? fechaStr;
      if (_fechaSeleccionada != null) {
        fechaStr = _fechaSeleccionada!.toIso8601String().split('T')[0];
      }

      String? horaInicioStr;
      if (_horaInicio != null) {
        horaInicioStr =
            '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}';
      }

      String? horaFinStr;
      if (_horaFin != null) {
        horaFinStr =
            '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}';
      }

      await RutinaService.guardarRutina(
        creatorId: SessionService.userId!,
        titulo: _tituloController.text.trim(),
        descripcion: _comentarioGeneralController.text.trim().isNotEmpty
            ? _comentarioGeneralController.text.trim()
            : null,
        clienteAsignadoId: _clienteSeleccionadoId,
        fecha: fechaStr,
        horaInicio: horaInicioStr,
        horaFin: horaFinStr,
        ejercicios: ejerciciosData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutina guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _abrirBuscador() async {
    final resultado = await Navigator.pushNamed(context, '/search-ejercicio');

    if (resultado != null && resultado is ConfiguredExercise) {
      setState(() {
        listaEjerciciosConfigurados.add(resultado);
      });
    }
  }

  Future<bool?> _showConfirmDeleteDialog(String exerciseName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondarySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar ejercicio?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se eliminará "$exerciseName" de la rutina, incluyendo todas sus series y notas. Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ATRÁS', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AppBackground(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      _buildSelectorCliente(),
                      const SizedBox(height: 15),
                      _buildDateTimeRow(),
                      const SizedBox(height: 25),
                      _buildInputTitulo(),
                      const SizedBox(height: 30),

                      // --- LISTA DE EJERCICIOS ---
                      if (listaEjerciciosConfigurados.isEmpty)
                        _buildEmptyState()
                      else
                        ...listaEjerciciosConfigurados.map((ejercicio) {
                          return _buildExerciseCard(
                            ejercicio: ejercicio,
                            onDelete: () async {
                              final confirm = await _showConfirmDeleteDialog(
                                ejercicio.exercise.name,
                              );
                              if (confirm == true) {
                                if (!context.mounted) return;
                                setState(() {
                                  listaEjerciciosConfigurados.removeWhere(
                                    (e) => e.instanceId == ejercicio.instanceId,
                                  );
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${ejercicio.exercise.name} eliminado",
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.grey[800],
                                  ),
                                );
                              }
                            },
                            onInfo: () {
                              Navigator.pushNamed(
                                context,
                                '/exercise-detail',
                                arguments: ejercicio.exercise,
                              );
                            },
                            onEdit: () async {
                              final resultadoEditado = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExerciseConfigScreen(
                                    exercise: ejercicio.exercise,
                                    existingConfig: ejercicio,
                                  ),
                                ),
                              );

                              if (resultadoEditado != null &&
                                  resultadoEditado is ConfiguredExercise) {
                                setState(() {
                                  int index = listaEjerciciosConfigurados
                                      .indexWhere(
                                        (e) =>
                                            e.instanceId ==
                                            ejercicio.instanceId,
                                      );
                                  if (index != -1) {
                                    listaEjerciciosConfigurados[index] =
                                        resultadoEditado;
                                  }
                                });
                              }
                            },
                          );
                        }),

                      const SizedBox(height: 15),
                      _buildAddButton(),
                      const SizedBox(height: 25),

                      // --- SECCIÓN DE COMENTARIO GENERAL ---
                      _buildGeneralCommentSection(),

                      const SizedBox(height: 20),
                      _buildCreateSessionButton(),
                      const SizedBox(height: 40),
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

  Widget _buildExerciseCard({
    required ConfiguredExercise ejercicio,
    required VoidCallback onDelete,
    required VoidCallback onInfo,
    required VoidCallback onEdit,
  }) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ejercicio.exercise.thumbnailImageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.white10,
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ejercicio.exercise.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ejercicio.notes.isEmpty
                        ? "Sin comentario agregado."
                        : ejercicio.notes,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onInfo,
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.accentLila,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "COMENTARIOS DE LA RUTINA",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _comentarioGeneralController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Añade instrucciones generales para esta sesión...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.cardBg.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(15),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Crear Rutina",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSelectorCliente() {
    return GestureDetector(
      onTap: () {
        if (_clientes.isEmpty) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.secondarySurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Seleccionar cliente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.white54),
                  title: const Text(
                    'Sin asignar',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    setState(() {
                      _clienteSeleccionadoId = null;
                      _clienteSeleccionadoNombre = 'Sin asignar';
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ..._clientes.map((rel) {
                  final perfil = rel['client'] as Map<String, dynamic>? ?? {};
                  final nombre =
                      (perfil['nombre'] ?? perfil['username'] ?? 'Sin nombre')
                          as String;
                  final id = perfil['id'] as String;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4B4584),
                      child: Text(
                        nombre[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      nombre,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: _clienteSeleccionadoId == id
                        ? const Icon(Icons.check, color: AppColors.accentLila)
                        : null,
                    onTap: () {
                      setState(() {
                        _clienteSeleccionadoId = id;
                        _clienteSeleccionadoNombre = nombre;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cliente: $_clienteSeleccionadoNombre',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTitulo() {
    return TextField(
      controller: _tituloController,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: "Título de la rutina",
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.dimmedColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDateTimeRow() {
    final fechaStr = _fechaSeleccionada != null
        ? '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'
        : 'Fecha';
    final inicioStr = _horaInicio != null
        ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}'
        : 'Inicio';
    final finStr = _horaFin != null
        ? '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}'
        : 'Fin';

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _seleccionarFecha,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fechaStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _seleccionarHora(esInicio: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                inicioStr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _seleccionarHora(esInicio: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                finStr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // IMAGEN PNG
          // Asegúrate de añadir la ruta en tu pubspec.yaml
          Image.asset(
            'assets/images/mancuerna.png',
            width: 180, // Ajusta el tamaño según tu imagen
            height: 180,
            fit: BoxFit.contain,
            // Este opacity es opcional, por si el PNG es muy brillante
            // y quieres que se fusione mejor con el fondo
            opacity: const AlwaysStoppedAnimation(0.8),
            errorBuilder: (context, error, stackTrace) {
              // Si aún no has puesto el archivo, mostrará un icono por defecto
              return const Icon(
                Icons.add_card,
                size: 80,
                color: Colors.white10,
              );
            },
          ),
          const SizedBox(height: 20),
          // TEXTO
          const Text(
            "Tu rutina está vacía",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Pulsa el botón de abajo para empezar\na configurar tus ejercicios.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPurple,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _abrirBuscador,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        "Agregar nuevo ejercicio",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildCreateSessionButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.accentLila),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _guardando ? null : _guardarRutina,
        child: _guardando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentLila,
                ),
              )
            : const Text(
                "GUARDAR RUTINA",
                style: TextStyle(
                  color: AppColors.accentLila,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
