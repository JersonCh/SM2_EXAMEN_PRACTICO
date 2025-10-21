import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/validador_service.dart';
import 'seleccion_registro_view.dart';
import 'dashboard_user_view.dart';
import 'dashboard_admin_view.dart';
import 'dashboard_expositor_view.dart';
import 'recuperar_paso1.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      await authViewModel.login(
        _correoController.text.trim(),
        _contrasenaController.text,
      );

      if (mounted && authViewModel.state == AuthState.success) {
        final rol = authViewModel.currentUser?.rol ?? 'usuario';
        Widget destino;
        if (rol == 'administrador') {
          destino = const DashboardAdminView();
        } else if (rol == 'expositor') {
          destino = const DashboardExpositorView();
        } else if (rol == 'usuario') {
          destino = const DashboardUserView();
        } else {
          destino = const DashboardUserView();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destino),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'logo',
                    child: Container(
                      height: size.height * 0.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B1B1B).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.festival,
                            size: 120,
                            color: Color(0xFF8B1B1B),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B1B1B).withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFF8B1B1B),
                              const Color(0xFF8B1B1B).withOpacity(0.8),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            '¡Bienvenidos!',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                              fontFamily: 'Roboto',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa a tu cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B1B1B),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Campo de correo
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _correoController,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF8B1B1B)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email, color: Color(0xFF8B1B1B)),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: ValidadorService.validarCorreo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Campo de contraseña
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _contrasenaController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF8B1B1B)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF8B1B1B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF8B1B1B),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      obscureText: _obscurePassword,
                      validator: ValidadorService.validarContrasena,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Olvidar contraseña
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecuperarPaso1(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            '¿Olvidaste tu contraseña? Pulsa AQUÍ',
                            style: TextStyle(
                              color: const Color(0xFF8B1B1B),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Estado de autenticación y botón
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return Column(
                        children: [
                          // Mostrar loading
                          if (authViewModel.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF8B1B1B),
                              ),
                            ),
                          // Mostrar error
                          if (authViewModel.state == AuthState.error)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Text(
                                authViewModel.errorMessage,
                                style: TextStyle(color: Colors.red.shade700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // Botón de login
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF8B1B1B),
                                  const Color(0xFF8B1B1B).withOpacity(0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B1B1B).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: authViewModel.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1B1B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                disabledBackgroundColor: const Color(0xFF8B1B1B).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shadowColor: const Color(0xFF8B1B1B),
                              ),
                              child: Text(
                                authViewModel.isLoading
                                    ? 'Iniciando sesión...'
                                    : 'Login',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Enlace a registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SeleccionRegistroView(),
                            ),
                          );
                        },
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(
                            color: Color(0xFF8B1B1B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}