import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/app_colors.dart';

class RegistrarseScreen extends StatelessWidget {
  const RegistrarseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Eliminamos el MaterialApp para usar el del main.dart
    // Usamos Theme para asegurar que los inputs y textos sigan el estilo visual
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
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // Importante: backgroundColor transparente para que se vea el gradiente del Container
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.loginGradient
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 70.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
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
              const SizedBox(height: 60),
              _buildCustomInput(
                hint: "Nombre completo",
                lineColor: AppColors.dimmedColor,
                hintColor: AppColors.hintText,
              ),
              const SizedBox(height: 25),
              _buildCustomInput(
                hint: "Fecha Nac. DD/MM/AA",
                lineColor: AppColors.dimmedColor,
                hintColor: AppColors.hintText,
              ),
              const SizedBox(height: 25),
              _buildCustomInput(
                hint: "Email",
                lineColor: AppColors.dimmedColor,
                hintColor: AppColors.hintText,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              _buildCustomInput(
                hint: "Contraseña",
                lineColor: AppColors.dimmedColor,
                hintColor: AppColors.hintText,
                obscureText: true,
              ),
              const SizedBox(height: 25),
              _buildPhoneInput(lineColor: AppColors.dimmedColor, hintColor: AppColors.hintText),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Aceptar términos y\ncondiciones',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _termsAccepted,
                      onChanged: (val) => setState(() => _termsAccepted = val!),
                      side: BorderSide(color: AppColors.dimmedColor, width: 1.5),
                      activeColor: Colors.transparent,
                      checkColor: AppColors.dimmedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              SizedBox(
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    // Acción de registro
                    Navigator.pushNamed(context, '/resumen');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textColor,
                    side: BorderSide(color: AppColors.dimmedColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    'Crear Cuenta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textColor, fontSize: 13),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomInput({
    required String hint,
    required Color lineColor,
    required Color hintColor,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 16),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: lineColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor, width: 2),
        ),
        contentPadding: const EdgeInsets.only(bottom: 12),
      ),
    );
  }

  Widget _buildPhoneInput({
    required Color lineColor,
    required Color hintColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: lineColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  '+34',
                  style: TextStyle(color: AppColors.textColor, fontSize: 16),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Teléfono',
                hintStyle: TextStyle(color: hintColor, fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 8),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
