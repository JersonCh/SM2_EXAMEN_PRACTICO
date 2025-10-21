import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recuperacion_viewmodel.dart';
import 'recuperar_paso3.dart';

class RecuperarPaso2 extends StatefulWidget {
  final String correo;

  const RecuperarPaso2({super.key, required this.correo});

  @override
  State<RecuperarPaso2> createState() => _RecuperarPaso2State();
}

class _RecuperarPaso2State extends State<RecuperarPaso2> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

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

  String _obtenerCodigo() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _limpiarCodigo() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Código'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Ingresa el código de verificación',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enviamos un código de 6 dígitos a:\n${widget.correo}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
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
                              final codigo = _obtenerCodigo();
                              if (codigo.length != 6) {
                                _mostrarModal(
                                  'Código Incompleto',
                                  'Por favor, ingresa los 6 dígitos del código.',
                                );
                                return;
                              }

                              final resultado = await viewModel.validarCodigo(
                                widget.correo,
                                codigo,
                              );

                              if (resultado['valido'] && mounted) {
                                _mostrarModal(
                                  'Código Válido',
                                  'Código verificado correctamente. Ahora puedes cambiar tu contraseña.',
                                  esExito: true,
                                );

                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) {
                                    Navigator.of(context).pop(); // Cerrar modal
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => RecuperarPaso3(
                                              correo: widget.correo,
                                            ),
                                      ),
                                    );
                                  }
                                });
                              } else {
                                String mensaje;
                                switch (resultado['razon']) {
                                  case 'codigo_incorrecto':
                                    mensaje =
                                        'El código ingresado no coincide. Verifica e intenta nuevamente.';
                                    break;
                                  case 'codigo_expirado':
                                    mensaje =
                                        'El código ha expirado. Solicita uno nuevo.';
                                    break;
                                  default:
                                    mensaje =
                                        'Error validando el código. Intenta nuevamente.';
                                }

                                _mostrarModal('Error', mensaje);
                                _limpiarCodigo();
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
                              'Verificar Código',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () async {
                  final viewModel = Provider.of<RecuperacionViewModel>(
                    context,
                    listen: false,
                  );
                  final exito = await viewModel.enviarCodigo(widget.correo);

                  if (exito) {
                    _mostrarModal(
                      'Código Reenviado',
                      'Se ha enviado un nuevo código a tu correo electrónico.',
                      esExito: true,
                    );
                    _limpiarCodigo();
                  } else {
                    _mostrarModal(
                      'Error',
                      'No se pudo reenviar el código. Intenta más tarde.',
                    );
                  }
                },
                child: const Text(
                  'Reenviar código',
                  style: TextStyle(color: Color(0xFF1976D2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
