import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recuperacion_viewmodel.dart';
import '../services/validador_service.dart';
import '../views/login_view.dart';

class RecuperarPaso3 extends StatefulWidget {
  final String correo;

  const RecuperarPaso3({super.key, required this.correo});

  @override
  State<RecuperarPaso3> createState() => _RecuperarPaso3State();
}

class _RecuperarPaso3State extends State<RecuperarPaso3> {
  final _formKey = GlobalKey<FormState>();
  final _contrasenaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _obscureContrasena = true;
  bool _obscureConfirmar = true;

  void _mostrarModal(
    String titulo,
    String mensaje, {
    bool esExito = false,
    VoidCallback? onCerrar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                esExito ? Icons.check_circle : Icons.error,
                color: esExito ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(titulo),
            ],
          ),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCerrar?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Contraseña'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Crear nueva contraseña',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu nueva contraseña debe tener al menos 6 caracteres.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _contrasenaController,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureContrasena
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscureContrasena = !_obscureContrasena,
                        ),
                  ),
                ),
                obscureText: _obscureContrasena,
                validator: ValidadorService.validarContrasena,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmarController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmar
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscureConfirmar = !_obscureConfirmar,
                        ),
                  ),
                ),
                obscureText: _obscureConfirmar,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme su contraseña';
                  }
                  if (value != _contrasenaController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer<RecuperacionViewModel>(
                builder: (context, viewModel, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1B1B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          viewModel.estado == EstadoRecuperacion.cargando
                              ? null
                              : () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  print('🔄 Intentando cambiar contraseña');
                                  print('📧 Correo del widget: ${widget.correo}');
                                  print('🔐 Nueva contraseña: ${_contrasenaController.text}');
                                  
                                  final exito = await viewModel
                                      .cambiarContrasena(
                                        _contrasenaController.text,
                                      );

                                  if (exito && mounted) {
                                    _mostrarModal(
                                      'Contraseña Cambiada',
                                      'Tu contraseña ha sido cambiada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña.',
                                      esExito: true,
                                      onCerrar: () {
                                        // Regresar al login y limpiar todas las pantallas de recuperación
                                        Navigator.of(
                                          context,
                                        ).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => const LoginView(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                    );
                                  } else {
                                    _mostrarModal(
                                      'Error',
                                      'No se pudo cambiar la contraseña. El código puede haber expirado.',
                                    );
                                  }
                                }
                              },
                      child:
                          viewModel.estado == EstadoRecuperacion.cargando
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Cambiar Contraseña',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contrasenaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }
}
