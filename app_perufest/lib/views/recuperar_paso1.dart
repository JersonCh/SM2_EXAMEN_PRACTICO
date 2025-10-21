import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recuperacion_viewmodel.dart';
import 'recuperar_paso2.dart';

class RecuperarPaso1 extends StatefulWidget {
  const RecuperarPaso1({super.key});

  @override
  State<RecuperarPaso1> createState() => _RecuperarPaso1State();
}

class _RecuperarPaso1State extends State<RecuperarPaso1> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();

  void _mostrarModal(String titulo, String mensaje, {bool esExito = false}) {
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
        title: const Text('Recuperar Contraseña'),
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
                'Ingresa tu correo electrónico',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Te enviaremos un código de 6 dígitos para recuperar tu contraseña.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese su correo';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return 'Ingrese un correo válido';
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
                                  final exito = await viewModel.enviarCodigo(
                                    _correoController.text,
                                  );

                                  if (exito && mounted) {
                                    _mostrarModal(
                                      'Código Enviado',
                                      'Se ha enviado un código de 6 dígitos a tu correo electrónico. Válido por 15 minutos.',
                                      esExito: true,
                                    );

                                    Future.delayed(
                                      const Duration(seconds: 2),
                                      () {
                                        if (mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Cerrar modal
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => RecuperarPaso2(
                                                    correo:
                                                        _correoController.text,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    _mostrarModal(
                                      'Error',
                                      'No se encontró una cuenta con este correo electrónico.',
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
                                'Enviar Código',
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
    _correoController.dispose();
    super.dispose();
  }
}
