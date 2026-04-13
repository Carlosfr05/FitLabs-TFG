import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class RegistrarseScreen extends StatelessWidget {
  const RegistrarseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
      ),
      child: const RegisterScreen(),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  DateTime? _birthDate;
  bool _emailSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 16),
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentLila,
            onPrimary: Colors.white,
            surface: const Color(0xFF1E1E2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String? _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) return 'El nombre es obligatorio.';
    if (email.isEmpty || !email.contains('@')) {
      return 'Introduce un email v\u00e1lido.';
    }
    if (password.length < 6) {
      return 'La contrase\u00f1a debe tener al menos 6 caracteres.';
    }
    if (password != confirm) {
      return 'Las contraseñas no coinciden.';
    }
    if (!_termsAccepted) {
      return 'Debes aceptar los términos y condiciones.';
    }
    return null;
  }

  Future<void> _signUp() async {
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'nombre': name, 'telefono': phone},
      );

      if (response.user != null && response.session == null) {
        setState(() => _emailSent = true);
      } else if (response.user != null && response.session != null) {
        await _crearPerfil(response.user!.id, name, email, phone);
        if (mounted) Navigator.pushReplacementNamed(context, '/resumen');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _crearPerfil(
    String userId,
    String nombre,
    String email,
    String telefono,
  ) async {
    final existe = await Supabase.instance.client
        .from('perfiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (existe == null) {
      await Supabase.instance.client.from('perfiles').insert({
        'id': userId,
        'username': nombre,
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'rol': 'entrenador',
        'role': 'entrenador',
        if (_birthDate != null)
          'fecha_nacimiento': _birthDate!.toIso8601String().split('T')[0],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: AppColors.loginGradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.accentLila,
                  size: 80,
                ),
                const SizedBox(height: 30),
                const Text(
                  '¡Revisa tu email!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Te hemos enviado un enlace de confirmación. Una vez que confirmes tu cuenta, vuelve e inicia sesión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.dimmedColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      foregroundColor: AppColors.textColor,
                    ),
                    child: const Text(
                      'Ir al Inicio de Sesión',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.loginGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 70),
              const Text(
                'Regístrate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 50),

              // Nombre completo
              _buildInput(
                hint: 'Nombre completo',
                controller: _nameController,
                focusNode: _nameFocus,
                nextFocus: _emailFocus,
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              // Email
              _buildInput(
                hint: 'Email',
                controller: _emailController,
                focusNode: _emailFocus,
                nextFocus: _passwordFocus,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Contraseña
              _buildInput(
                hint: 'Contraseña',
                controller: _passwordController,
                focusNode: _passwordFocus,
                nextFocus: _confirmPasswordFocus,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 20),

              // Confirmar contraseña
              _buildInput(
                hint: 'Confirmar contraseña',
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                nextFocus: _phoneFocus,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 20),

              // Teléfono
              _buildPhoneInput(),
              const SizedBox(height: 20),

              // Fecha de nacimiento
              _buildDatePicker(),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),

              // Términos
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _termsAccepted,
                      onChanged: (val) => setState(() => _termsAccepted = val!),
                      side: BorderSide(
                        color: AppColors.dimmedColor,
                        width: 1.5,
                      ),
                      activeColor: Colors.transparent,
                      checkColor: AppColors.dimmedColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Acepto los términos y condiciones de uso',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // Botón crear cuenta
              SizedBox(
                height: 55,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textColor,
                    side: BorderSide(color: AppColors.dimmedColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.dimmedColor,
                          ),
                        )
                      : const Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              Center(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'Volver a la página de '),
                        TextSpan(
                          text: 'Inicio de sesión',
                          style: TextStyle(
                            color: AppColors.dimmedColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      autofillHints: autofillHints,
      onSubmitted: (_) {
        if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
      },
      style: const TextStyle(color: AppColors.textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.hintText, fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.dimmedColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor, width: 2),
        ),
        contentPadding: const EdgeInsets.only(bottom: 10),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      focusNode: _phoneFocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      style: const TextStyle(color: AppColors.textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Teléfono (opcional)',
        hintStyle: TextStyle(color: AppColors.hintText, fontSize: 15),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 10, left: 4, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 8),
              Icon(Icons.phone_outlined, color: Colors.white38, size: 20),
              SizedBox(width: 8),
              Text(
                '+34',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              SizedBox(width: 4),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.dimmedColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor, width: 2),
        ),
        contentPadding: const EdgeInsets.only(bottom: 10),
      ),
    );
  }

  Widget _buildDatePicker() {
    final label = _birthDate != null
        ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
        : 'Fecha de nacimiento (opcional)';

    return InkWell(
      onTap: _pickBirthDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.dimmedColor)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.cake_outlined, color: Colors.white38, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: _birthDate != null
                    ? AppColors.textColor
                    : AppColors.hintText,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (_birthDate != null)
              GestureDetector(
                onTap: () => setState(() => _birthDate = null),
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
