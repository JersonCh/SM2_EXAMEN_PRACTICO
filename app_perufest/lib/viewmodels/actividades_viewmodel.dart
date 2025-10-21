import 'package:flutter/foundation.dart';
import '../models/actividad.dart';
import '../services/actividades_service.dart';
import '../services/timezone.dart';

enum ActividadesState { idle, loading, success, error }

class ActividadesViewModel extends ChangeNotifier {
  final ActividadesService _actividadesService = ActividadesService();
  
  ActividadesState _state = ActividadesState.idle;
  String _errorMessage = '';
  List<Actividad> _actividades = [];
  Map<DateTime, List<Actividad>> _actividadesPorDia = {};
  String _eventoIdActual = '';

  // Getters
  ActividadesState get state => _state;
  String get errorMessage => _errorMessage;
  List<Actividad> get actividades => _actividades;
  Map<DateTime, List<Actividad>> get actividadesPorDia => _actividadesPorDia;
  bool get isLoading => _state == ActividadesState.loading;
  bool get hasActividades => _actividades.isNotEmpty;
  String get eventoIdActual => _eventoIdActual;

  // Cargar actividades de un evento específico
  Future<void> cargarActividadesPorEvento(String eventoId) async {
    _eventoIdActual = eventoId;
    _setState(ActividadesState.loading);
    
    try {
      print('DEBUG: Cargando actividades para evento: $eventoId');
      _actividades = await _actividadesService.obtenerActividadesPorEvento(eventoId);
      _actividadesPorDia = await _actividadesService.obtenerActividadesAgrupadasPorDia(eventoId);
      _setState(ActividadesState.success);
      
      print('DEBUG: Actividades cargadas: ${_actividades.length}');
      print('DEBUG: Días con actividades: ${_actividadesPorDia.keys.length}');
      for (var entrada in _actividadesPorDia.entries) {
        print('DEBUG: Día ${entrada.key}: ${entrada.value.length} actividades');
        for (var actividad in entrada.value) {
          print('DEBUG:   - ${actividad.nombre} (${actividad.horario})');
        }
      }
      
      if (kDebugMode) {
        debugPrint('Actividades cargadas: ${_actividades.length}');
      }
    } catch (e) {
      _setError('Error al cargar las actividades');
      if (kDebugMode) {
        debugPrint('Error al cargar actividades: $e');
      }
    }
  }

  // Crear nueva actividad
  Future<bool> crearActividad(Actividad actividad) async {
    try {
      _setState(ActividadesState.loading);
      
      final exito = await _actividadesService.crearActividad(actividad);
      
      if (exito) {
        // Recargar las actividades para obtener la nueva con su ID
        await cargarActividadesPorEvento(actividad.eventoId);
        return true;
      } else {
        _setError('Error al crear la actividad');
        return false;
      }
    } catch (e) {
      _setError('Error inesperado al crear la actividad');
      if (kDebugMode) {
        debugPrint('Error al crear actividad: $e');
      }
      return false;
    }
  }

  // Actualizar actividad existente
  Future<bool> actualizarActividad(Actividad actividad) async {
    try {
      _setState(ActividadesState.loading);
      
      final exito = await _actividadesService.actualizarActividad(actividad);
      
      if (exito) {
        // Actualizar en la lista local
        final index = _actividades.indexWhere((a) => a.id == actividad.id);
        if (index != -1) {
          _actividades[index] = actividad.copyWith(fechaActualizacion: TimezoneUtils.now()); // Changed this line
        }
        
        // Recargar para actualizar agrupación por días
        await cargarActividadesPorEvento(actividad.eventoId);
        return true;
      } else {
        _setError('Error al actualizar la actividad');
        return false;
      }
    } catch (e) {
      _setError('Error inesperado al actualizar la actividad');
      if (kDebugMode) {
        debugPrint('Error al actualizar actividad: $e');
      }
      return false;
    }
  }

  // Eliminar actividad
  Future<bool> eliminarActividad(String actividadId) async {
    try {
      _setState(ActividadesState.loading);
      
      final exito = await _actividadesService.eliminarActividad(actividadId);
      
      if (exito) {
        // Remover de la lista local
        _actividades.removeWhere((a) => a.id == actividadId);
        
        // Recargar para actualizar agrupación por días
        if (_eventoIdActual.isNotEmpty) {
          await cargarActividadesPorEvento(_eventoIdActual);
        }
        return true;
      } else {
        _setError('Error al eliminar la actividad');
        return false;
      }
    } catch (e) {
      _setError('Error inesperado al eliminar la actividad');
      if (kDebugMode) {
        debugPrint('Error al eliminar actividad: $e');
      }
      return false;
    }
  }

  // Verificar conflictos de horario
  Future<List<Actividad>> verificarConflictosHorario(
    String eventoId,
    String zona,
    DateTime fechaInicio,
    DateTime fechaFin,
    {String? actividadIdExcluir}
  ) async {
    try {
      return await _actividadesService.verificarConflictosHorario(
        eventoId,
        zona,
        fechaInicio,
        fechaFin,
        actividadIdExcluir: actividadIdExcluir,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al verificar conflictos: $e');
      }
      return [];
    }
  }

  // Obtener actividades de un día específico
  List<Actividad> obtenerActividadesDeDia(DateTime fecha) {
    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final actividades = _actividadesPorDia[fechaSinHora] ?? [];
    
    print('DEBUG: Buscando actividades para fecha: $fechaSinHora');
    print('DEBUG: Actividades encontradas: ${actividades.length}');
    
    return actividades;
  }

  // Generar días del evento para mostrar tabs/secciones
  List<DateTime> generarDiasDelEvento(DateTime fechaInicio, DateTime fechaFin) {
    final dias = <DateTime>[];
    var fechaActual = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fechaFinal = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

    while (fechaActual.isBefore(fechaFinal) || fechaActual.isAtSameMomentAs(fechaFinal)) {
      dias.add(fechaActual);
      fechaActual = fechaActual.add(const Duration(days: 1));
    }

    return dias;
  }

  // Validar si una fecha está dentro del rango del evento
  bool fechaDentroDelEvento(DateTime fecha, DateTime inicioEvento, DateTime finEvento) {
    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final inicioSinHora = DateTime(inicioEvento.year, inicioEvento.month, inicioEvento.day);
    final finSinHora = DateTime(finEvento.year, finEvento.month, finEvento.day);

    return (fechaSinHora.isAtSameMomentAs(inicioSinHora) || fechaSinHora.isAfter(inicioSinHora)) &&
           (fechaSinHora.isAtSameMomentAs(finSinHora) || fechaSinHora.isBefore(finSinHora));
  }

  // Limpiar datos cuando se cambie de evento
  void limpiar() {
    _actividades.clear();
    _actividadesPorDia.clear();
    _eventoIdActual = '';
    _state = ActividadesState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  // Métodos privados
  void _setState(ActividadesState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(ActividadesState.error);
  }
}