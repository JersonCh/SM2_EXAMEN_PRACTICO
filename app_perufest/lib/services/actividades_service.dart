import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/actividad.dart';
import '../services/timezone.dart';

class ActividadesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _coleccion = 'actividades';

  // Crear nueva actividad
  Future<bool> crearActividad(Actividad actividad) async {
    try {
      await _firestore.collection(_coleccion).add(actividad.toFirestore());
      return true;
    } catch (e) {
      print('Error al crear actividad: $e');
      return false;
    }
  }

  // Obtener actividades de un evento específico
  Future<List<Actividad>> obtenerActividadesPorEvento(String eventoId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_coleccion)
          .where('eventoId', isEqualTo: eventoId)
          .orderBy('fechaInicio')
          .get();

      return querySnapshot.docs
          .map((doc) => Actividad.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error al obtener actividades: $e');
      return [];
    }
  }

  // Obtener actividades de un evento agrupadas por día
  Future<Map<DateTime, List<Actividad>>> obtenerActividadesAgrupadasPorDia(String eventoId) async {
    try {
      final actividades = await obtenerActividadesPorEvento(eventoId);
      final Map<DateTime, List<Actividad>> actividadesPorDia = {};

      for (final actividad in actividades) {
        // Use Peru timezone for grouping by day
        final fechaPeruana = TimezoneUtils.toPeru(actividad.fechaInicio);
        final fecha = DateTime(
          fechaPeruana.year,
          fechaPeruana.month,
          fechaPeruana.day,
        );

        if (!actividadesPorDia.containsKey(fecha)) {
          actividadesPorDia[fecha] = [];
        }
        actividadesPorDia[fecha]!.add(actividad);
      }

      return actividadesPorDia;
    } catch (e) {
      print('Error al obtener actividades agrupadas: $e');
      return {};
    }
  }

  // Actualizar actividad
  Future<bool> actualizarActividad(Actividad actividad) async {
    try {
      final actividadActualizada = actividad.copyWith(
        fechaActualizacion: TimezoneUtils.now(), // Use Peru timezone
      );

      await _firestore
          .collection(_coleccion)
          .doc(actividad.id)
          .update(actividadActualizada.toFirestore());
      
      return true;
    } catch (e) {
      print('Error al actualizar actividad: $e');
      return false;
    }
  }

  // Eliminar actividad
  Future<bool> eliminarActividad(String actividadId) async {
    try {
      await _firestore.collection(_coleccion).doc(actividadId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar actividad: $e');
      return false;
    }
  }

  // Obtener una actividad específica
  Future<Actividad?> obtenerActividad(String actividadId) async {
    try {
      final doc = await _firestore.collection(_coleccion).doc(actividadId).get();
      if (doc.exists) {
        return Actividad.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener actividad: $e');
      return null;
    }
  }

  // Verificar si hay conflictos de horario en una zona
  Future<List<Actividad>> verificarConflictosHorario(
    String eventoId, 
    String zona, 
    DateTime fechaInicio, 
    DateTime fechaFin,
    {String? actividadIdExcluir}
  ) async {
    try {
      Query query = _firestore
          .collection(_coleccion)
          .where('eventoId', isEqualTo: eventoId)
          .where('zona', isEqualTo: zona);

      final querySnapshot = await query.get();
      final actividades = querySnapshot.docs
          .map((doc) => Actividad.fromFirestore(doc))
          .where((actividad) {
            // Excluir la actividad actual si se está editando
            if (actividadIdExcluir != null && actividad.id == actividadIdExcluir) {
              return false;
            }
            
            // Verificar superposición de horarios
            return (fechaInicio.isBefore(actividad.fechaFin) && 
                    fechaFin.isAfter(actividad.fechaInicio));
          })
          .toList();

      return actividades;
    } catch (e) {
      print('Error al verificar conflictos: $e');
      return [];
    }
  }

  // Escuchar cambios en tiempo real para un evento
  Stream<List<Actividad>> escucharActividadesPorEvento(String eventoId) {
    return _firestore
        .collection(_coleccion)
        .where('eventoId', isEqualTo: eventoId)
        .orderBy('fechaInicio')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Actividad.fromFirestore(doc))
            .toList());
  }

  // Eliminar todas las actividades de un evento
  Future<bool> eliminarTodasLasActividadesDelEvento(String eventoId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_coleccion)
          .where('eventoId', isEqualTo: eventoId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error al eliminar actividades del evento: $e');
      return false;
    }
  }
}