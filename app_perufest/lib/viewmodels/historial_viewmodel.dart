import 'package:flutter/foundation.dart';
import '../models/registro_inicio.dart';
import '../services/historial_service.dart';

enum HistorialState { idle, loading, success, error }

class HistorialViewModel extends ChangeNotifier {
  HistorialState _state = HistorialState.idle;
  String _errorMessage = '';
  List<RegistroInicio> _registros = [];

  HistorialState get state => _state;
  String get errorMessage => _errorMessage;
  List<RegistroInicio> get registros => _registros;
  bool get isLoading => _state == HistorialState.loading;

  void _setState(HistorialState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(HistorialState.error);
  }

  // Cargar historial de un usuario
  Future<void> cargarHistorial(String usuarioId) async {
    if (_state == HistorialState.loading) return;

    _setState(HistorialState.loading);

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      _registros = await HistorialService.obtenerHistorialUsuario(usuarioId);
      
      if (_registros.isEmpty) {
        _setState(HistorialState.idle);
      } else {
        _setState(HistorialState.success);
      }
    } catch (e) {
      _setError('Error al cargar el historial: ${e.toString()}');
    }
  }

  // Refrescar historial
  Future<void> refrescarHistorial(String usuarioId) async {
    _registros.clear();
    await cargarHistorial(usuarioId);
  }

  // Limpiar estado
  void limpiarEstado() {
    _state = HistorialState.idle;
    _errorMessage = '';
    _registros.clear();
    notifyListeners();
  }

  // Formatear fecha para mostrar
  String formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inDays == 0) {
      return 'Hoy ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días atrás';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  // Obtener fecha específica para mostrar como descripción adicional
  String obtenerFechaEspecifica(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}