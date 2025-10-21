import 'package:flutter/foundation.dart';
import '../services/recuperacion_service.dart';

enum EstadoRecuperacion { inicial, cargando, exito, error }

class RecuperacionViewModel extends ChangeNotifier {
  final RecuperacionService _service = RecuperacionService();

  EstadoRecuperacion _estado = EstadoRecuperacion.inicial;
  String? _mensajeError;
  String? _correoActual;
  String? _codigoActual;

  EstadoRecuperacion get estado => _estado;
  String? get mensajeError => _mensajeError;
  String? get correoActual => _correoActual;

  void _setEstado(EstadoRecuperacion nuevoEstado, [String? error]) {
    _estado = nuevoEstado;
    _mensajeError = error;
    notifyListeners();
  }

  Future<bool> enviarCodigo(String correo) async {
    _setEstado(EstadoRecuperacion.cargando);

    try {
      final exito = await _service.enviarCodigoRecuperacion(correo);

      if (exito) {
        _correoActual = correo;
        _setEstado(EstadoRecuperacion.exito);
        return true;
      } else {
        _setEstado(EstadoRecuperacion.error, 'Correo no encontrado');
        return false;
      }
    } catch (e) {
      _setEstado(EstadoRecuperacion.error, 'Error enviando código');
      return false;
    }
  }

  Future<Map<String, dynamic>> validarCodigo(
    String correo,
    String codigo,
  ) async {
    _setEstado(EstadoRecuperacion.cargando);

    try {
      final esValido = await _service.verificarCodigo(correo, codigo);

      if (esValido) {
        _codigoActual = codigo;
        _setEstado(EstadoRecuperacion.exito);
        return {'valido': true};
      } else {
        _setEstado(EstadoRecuperacion.error, 'Código inválido o expirado');
        return {'valido': false, 'razon': 'codigo_invalido'};
      }
    } catch (e) {
      _setEstado(EstadoRecuperacion.error, 'Error validando código');
      return {'valido': false, 'razon': 'error_sistema'};
    }
  }

  Future<bool> cambiarContrasena(String nuevaContrasena) async {
    print('📧 Correo actual: $_correoActual');
    print('🔑 Código actual: $_codigoActual');
    if (_correoActual == null || _codigoActual == null) {
      print('❌ Error: Correo o código null');
      return false;
    }
    _setEstado(EstadoRecuperacion.cargando);

    try {
      // Usar el método directo para evitar doble verificación de código
      final exito = await _service.cambiarContrasenaDirecto(
        _correoActual!,
        _codigoActual!,
        nuevaContrasena,
      );

      if (exito) {
        _setEstado(EstadoRecuperacion.exito);
        limpiarDatos();
        return true;
      } else {
        _setEstado(EstadoRecuperacion.error, 'Error cambiando contraseña');
        return false;
      }
    } catch (e) {
      _setEstado(EstadoRecuperacion.error, 'Error cambiando contraseña');
      return false;
    }
  }

  void limpiarEstado() {
    _setEstado(EstadoRecuperacion.inicial);
  }

  void limpiarDatos() {
    _correoActual = null;
    _codigoActual = null;
    _setEstado(EstadoRecuperacion.inicial);
  }
}
