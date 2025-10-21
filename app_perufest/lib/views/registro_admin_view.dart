import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/validador_service.dart';
import 'login_view.dart';

class RegistroAdminView extends StatefulWidget {
  const RegistroAdminView({super.key});

  @override
  State<RegistroAdminView> createState() => _RegistroAdminViewState();
}

class _RegistroAdminViewState extends State<RegistroAdminView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.registrar(
        nombre: _nombreController.text.trim(),
        username: _usernameController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        rol: 'administrador',
        contrasena: _contrasenaController.text,
      );
      if (mounted && authViewModel.state == AuthState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Administrador registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: size.height * 0.15,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.admin_panel_settings,
                        size: 80,
                        color: Color(0xFF1976D2),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registro Administrador',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: ValidadorService.validarNombre,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                  validator: ValidadorService.validarUsername,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidadorService.validarCorreo,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: ValidadorService.validarTelefono,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contrasenaController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: ValidadorService.validarContrasena,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmarContrasenaController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed:
                          () => setState(
                            () =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                          ),
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator:
                      (value) => ValidadorService.validarConfirmarContrasena(
                        value,
                        _contrasenaController.text,
                      ),
                ),
                const SizedBox(height: 24),
                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    return Column(
                      children: [
                        if (authViewModel.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        if (authViewModel.state == AuthState.error)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              authViewModel.errorMessage,
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                authViewModel.isLoading ? null : _registrar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              authViewModel.isLoading
                                  ? 'Registrando...'
                                  : 'Registrarse',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
