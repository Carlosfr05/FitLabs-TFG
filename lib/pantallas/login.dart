import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor rellena todos los campos.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Introduce un email válido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Crear perfil si no existe (por ejemplo tras confirmar email)
      if (response.user != null) {
        final perfil = await Supabase.instance.client
            .from('perfiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();
        if (perfil == null) {
          await Supabase.instance.client.from('perfiles').insert({
            'id': response.user!.id,
            'username':
                response.user!.userMetadata?['nombre'] ?? email.split('@')[0],
            'nombre':
                response.user!.userMetadata?['nombre'] ?? email.split('@')[0],
            'email': email,
            'telefono': response.user!.userMetadata?['telefono'] ?? '',
            'rol': 'entrenador',
            'role': 'entrenador',
          });
        }
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/resumen');
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login') ||
          msg.contains('invalid credentials')) {
        setState(() => _errorMessage = 'Email o contraseña incorrectos.');
      } else if (msg.contains('email not confirmed')) {
        setState(
          () => _errorMessage = 'Confirma tu email antes de iniciar sesión.',
        );
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.loginGradient),
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),

                  // 1. LOGO CIRCULAR
                  const Image(
                    image: AssetImage('assets/images/logoFitlabs.png'),
                    width: 240,
                    height: 240,
                  ),

                  const SizedBox(height: 30),

                  // 2. TEXTO "FitLabs"
                  const Text(
                    "FitLabs",
                    style: TextStyle(
                      color: AppColors.dimmedColor,
                      fontSize: 56,
                      letterSpacing: 1.5,
                      fontFamily: 'RubikVinyl',
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. INPUT EMAIL
                  _buildMinimalInput(
                    label: "Email",
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passwordFocus,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 30),

                  // 4. INPUT CONTRASEÑA
                  _buildMinimalInput(
                    label: "Contraseña",
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    isPassword: true,
                    onSubmit: _signIn,
                  ),

                  // 5. MENSAJE DE ERROR
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
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

                  const Spacer(flex: 1),

                  // 6. BOTÓN "Iniciar Sesión"
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.dimmedColor,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        foregroundColor: AppColors.textColor,
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
                              "Iniciar Sesión",
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 7. TEXTO REGISTRO
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/registrarse'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(text: "¿No tienes cuenta? "),
                          TextSpan(
                            text: "Regístrate",
                            style: TextStyle(
                              color: AppColors.dimmedColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalInput({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          onSubmit?.call();
        }
      },
      style: const TextStyle(color: AppColors.textColor, fontSize: 16),
      cursorColor: AppColors.accentLila,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: AppColors.hintText),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.dimmedColor, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.dimmedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.only(bottom: 10),
      ),
    );
  }
}
