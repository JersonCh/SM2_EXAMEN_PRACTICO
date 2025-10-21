import 'package:flutter/foundation.dart';
import '../services/agenda_service.dart';
import '../services/notificaciones_service.dart';
class AgendaViewModel extends ChangeNotifier {
  final AgendaService _agendaService = AgendaService();
  final NotificacionesService _notificacionesService = NotificacionesService();

  final Map<String, bool> _actividadesEnAgenda = {};
  final Set<String> _actividadesCargando = {};
  String _userId = '';
  int _recordatorioTemporal = 30;

  String get userId => _userId;

  bool estaEnAgenda(String actividadId) {
    return _actividadesEnAgenda[actividadId] ?? false;
  }

  bool estaCargando(String actividadId) {
    return _actividadesCargando.contains(actividadId);
  }

  void configurarUsuario(String userId) {
    _userId = userId;
  }
  void setRecordatorioTemporal(int minutos) {
    _recordatorioTemporal = minutos;
  }

  Future<bool> alternarActividadEnAgenda(String actividadId) async {
    if (_userId.isEmpty) return false;

    _actividadesCargando.add(actividadId);
    notifyListeners();

    try {
      final estaEnAgenda = _actividadesEnAgenda[actividadId] ?? false;
      final exito = await _agendaService.alternarActividadEnAgenda(
        _userId, 
        actividadId, 
        estaEnAgenda,
        recordatorioMinutos: _recordatorioTemporal,
      );

      if (exito) {
        if (estaEnAgenda) {
          _actividadesEnAgenda.remove(actividadId);
        } else {
          _actividadesEnAgenda[actividadId] = true;
        }
      }

      return exito;
    } finally {
      _actividadesCargando.remove(actividadId);
      notifyListeners();
    }
  }

  Future<void> verificarEstadoActividades(List<String> actividadesIds) async {
    if (_userId.isEmpty) return;

    try {
      for (String actividadId in actividadesIds) {
        final estaEnAgenda = await _agendaService.estaEnAgenda(userId, actividadId);
        _actividadesEnAgenda[actividadId] = estaEnAgenda;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al verificar estado de actividades: $e');
      }
    }
  }

  void limpiar() {
    _actividadesEnAgenda.clear();
    _actividadesCargando.clear();
    _userId = '';
    notifyListeners();
  }
}