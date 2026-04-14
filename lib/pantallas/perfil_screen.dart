import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_background.dart';
import 'package:pantallas_fitlabs/core/app_bottom_navbar.dart';
import 'package:pantallas_fitlabs/data/session_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  late AnimationController _animCtrl;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  String _nombre = '';
  String _email = '';
  String _telefono = '';
  String _bio = '';
  String? _avatarUrl;
  String _role = '';
  String? _fechaNacimiento;
  String? _createdAt;

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  int get navIndex => SessionService.isEntrenador ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cargarPerfil();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final userId = SessionService.userId;
      if (userId == null) return;

      final data = await _supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nombre =
              data['nombre'] as String? ?? data['username'] as String? ?? '';
          _email = data['email'] as String? ?? '';
          _telefono = data['telefono'] as String? ?? '';
          _bio = data['bio'] as String? ?? '';
          _avatarUrl = data['avatar_url'] as String?;
          _role = data['role'] as String? ?? '';
          _fechaNacimiento = data['fecha_nacimiento'] as String?;
          _createdAt = data['created_at'] as String?;
          _nombreCtrl.text = _nombre;
          _telefonoCtrl.text = _telefono;
          _bioCtrl.text = _bio;
          _loading = false;
        });
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar perfil: $e')));
      }
    }
  }

  Future<void> _guardarPerfil() async {
    setState(() => _saving = true);
    try {
      final userId = SessionService.userId;
      if (userId == null) return;

      await _supabase
          .from('perfiles')
          .update({
            'nombre': _nombreCtrl.text.trim(),
            'username': _nombreCtrl.text.trim(),
            'telefono': _telefonoCtrl.text.trim(),
            'bio': _bioCtrl.text.trim(),
          })
          .eq('id', userId);

      // Actualizar SessionService
      await SessionService.cargarPerfil();

      if (mounted) {
        setState(() {
          _nombre = _nombreCtrl.text.trim();
          _telefono = _telefonoCtrl.text.trim();
          _bio = _bioCtrl.text.trim();
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  Future<void> _cambiarFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _opcionFoto(
                  icon: Icons.photo_library_rounded,
                  label: 'Galería',
                  onTap: () {
                    Navigator.pop(ctx);
                    _seleccionarFoto(ImageSource.gallery);
                  },
                ),
                _opcionFoto(
                  icon: Icons.camera_alt_rounded,
                  label: 'Cámara',
                  onTap: () {
                    Navigator.pop(ctx);
                    _seleccionarFoto(ImageSource.camera);
                  },
                ),
                if (_avatarUrl != null)
                  _opcionFoto(
                    icon: Icons.delete_rounded,
                    label: 'Eliminar',
                    color: AppColors.accentRed,
                    onTap: () {
                      Navigator.pop(ctx);
                      _eliminarFoto();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _opcionFoto({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? AppColors.accentPurple).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? AppColors.accentLila, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color ?? Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final userId = SessionService.userId!;
      final file = File(picked.path);
      final ext = picked.path.split('.').last.toLowerCase();
      final path = 'avatars/$userId.$ext';

      await _supabase.storage
          .from('chat-media')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabase.storage.from('chat-media').getPublicUrl(path);

      // Añadir timestamp para forzar recarga de caché
      final urlConTimestamp =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('perfiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      await SessionService.cargarPerfil();

      if (mounted) {
        setState(() {
          _avatarUrl = urlConTimestamp;
          _uploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
      }
    }
  }

  Future<void> _eliminarFoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      final userId = SessionService.userId!;

      await _supabase
          .from('perfiles')
          .update({'avatar_url': null})
          .eq('id', userId);

      await SessionService.cargarPerfil();

      if (mounted) {
        setState(() {
          _avatarUrl = null;
          _uploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar foto: $e')));
      }
    }
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento != null
          ? DateTime.tryParse(_fechaNacimiento!) ?? DateTime(2000)
          : DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: now,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentPurple,
              surface: AppColors.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    final formatted =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      await _supabase
          .from('perfiles')
          .update({'fecha_nacimiento': formatted})
          .eq('id', SessionService.userId!);

      if (mounted) {
        setState(() => _fechaNacimiento = formatted);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Seguro que quieres cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.accentLila),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _supabase.auth.signOut();
    SessionService.limpiar();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return 'No especificada';
    final dt = DateTime.tryParse(fecha);
    if (dt == null) return fecha;
    const meses = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${dt.day} de ${meses[dt.month]} de ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentLila),
              )
            : SafeArea(
                bottom: false,
                child: FadeTransition(
                  opacity: _animCtrl,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                    child: Column(
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 24),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildBioCard(),
                        const SizedBox(height: 16),
                        _buildDetallesCard(),
                        const SizedBox(height: 24),
                        _buildGuardarButton(),
                        const SizedBox(height: 16),
                        _buildCerrarSesionButton(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: navIndex),
    );
  }

  Widget _buildAvatarSection() {
    final initial = _nombre.isNotEmpty ? _nombre[0].toUpperCase() : '?';
    return Column(
      children: [
        GestureDetector(
          onTap: _cambiarFoto,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _avatarUrl == null
                      ? const LinearGradient(
                          colors: [
                            AppColors.accentPurple,
                            AppColors.accentLila,
                          ],
                        )
                      : null,
                  border: Border.all(color: AppColors.accentLila, width: 3),
                ),
                child: ClipOval(
                  child: _uploadingPhoto
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : _avatarUrl != null
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgTop, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _nombre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _role == 'entrenador' ? 'Entrenador' : 'Cliente',
            style: const TextStyle(
              color: AppColors.accentLila,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSummaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.accentLila, size: 20),
              SizedBox(width: 8),
              Text(
                'Información personal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nombreCtrl,
            label: 'Nombre completo',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 14),
          _buildReadOnlyField(
            label: 'Email',
            value: _email,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _telefonoCtrl,
            label: 'Teléfono',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSummaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: AppColors.accentLila,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Sobre mí',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioCtrl,
            maxLines: 4,
            maxLength: 200,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Escribe algo sobre ti...',
              hintStyle: const TextStyle(color: AppColors.hintText),
              counterStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.accentLila,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSummaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accentLila, size: 20),
              SizedBox(width: 8),
              Text(
                'Detalles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.cake_outlined,
            label: 'Fecha de nacimiento',
            value: _formatFecha(_fechaNacimiento),
            onTap: _seleccionarFechaNacimiento,
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Miembro desde',
            value: _formatFecha(_createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.accentLila, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentLila, width: 1),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accentLila.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildGuardarButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _guardarPerfil,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Guardar cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildCerrarSesionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _cerrarSesion,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Cerrar sesión', style: TextStyle(fontSize: 15)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentRed,
          side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
