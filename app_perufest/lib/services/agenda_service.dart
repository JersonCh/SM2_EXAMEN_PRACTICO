import 'package:cloud_firestore/cloud_firestore.dart';
import 'notificaciones_service.dart';
import '../models/actividad.dart';

class AgendaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String coleccion = 'agenda_usuarios';
  final NotificacionesService _notificacionesService = NotificacionesService();

  // Agregar actividad a agenda
  Future<bool> agregarActividadAAgenda(String userId, String actividadId) async {
    try {
      // Verificar si ya existe
      final existe = await _firestore
          .collection(coleccion)
          .where('userId', isEqualTo: userId)
          .where('actividadId', isEqualTo: actividadId)
          .get();
      
      if (existe.docs.isNotEmpty) {
        return false; // Ya existe
      }
      
      // Crear nuevo registro
      await _firestore.collection(coleccion).add({
        'userId': userId,
        'actividadId': actividadId,
        'fechaAgregado': FieldValue.serverTimestamp(),
        'estado': 'confirmado',
        'recordatorioMinutos': 30,
      });
      
      return true;
    } catch (e) {
      print('Error al agregar a agenda: $e');
      return false;
    }
  }

  // Quitar actividad de agenda
  Future<bool> quitarActividadDeAgenda(String userId, String actividadId) async {
    try {
      final query = await _firestore
          .collection(coleccion)
          .where('userId', isEqualTo: userId)
          .where('actividadId', isEqualTo: actividadId)
          .get();
      
      if (query.docs.isNotEmpty) {
        for (var doc in query.docs) {
          await doc.reference.delete();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error al quitar de agenda: $e');
      return false;
    }
  }

  // Verificar si una actividad está en la agenda del usuario
  Future<bool> estaEnAgenda(String userId, String actividadId) async {
    try {
      final doc = await _firestore.collection(coleccion).doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final actividades = List<String>.from(data['actividades'] ?? []);
        return actividades.contains(actividadId);
      }
      return false;
    } catch (e) {
      print('Error al verificar agenda: $e');
      return false;
    }
  }
  
  Future<bool> alternarActividadEnAgenda(String userId, String actividadId, bool estaEnAgenda, {int recordatorioMinutos = 30}) async {
    try {
      print('=== DEBUG AGENDA SERVICE ===');
      print('UserId: $userId');
      print('ActividadId: $actividadId');
      print('EstaEnAgenda: $estaEnAgenda');
      print('RecordatorioMinutos: $recordatorioMinutos');
      
      final docRef = _firestore.collection(coleccion).doc(userId);

      if (estaEnAgenda) {
        // Remover y cancelar notificación
        await docRef.update({
          'actividades': FieldValue.arrayRemove([actividadId]),
          'detalles.$actividadId': FieldValue.delete(),
        });
        
        await _notificacionesService.cancelarRecordatorio(actividadId);
        print('Actividad removida y notificación cancelada');
      } else {
        print('Agregando actividad a agenda...');
        
        // Obtener datos de la actividad para la notificación
        print('Obteniendo datos de actividad: $actividadId');
        final actividadDoc = await _firestore.collection('actividades').doc(actividadId).get();
        
        if (!actividadDoc.exists) {
          print('ERROR: Actividad no encontrada: $actividadId');
          return false;
        }
        
        print('Actividad encontrada, creando objeto...');
        final actividad = Actividad.fromFirestore(actividadDoc);
        print('Actividad creada: ${actividad.nombre}');
        
        // Agregar a agenda
        final agendaItem = {
          'actividadId': actividadId,
          'fechaAgregado': FieldValue.serverTimestamp(),
          'recordatorioMinutos': recordatorioMinutos,
        };

        print('Guardando en Firestore...');
        await docRef.set({
          'actividades': FieldValue.arrayUnion([actividadId]),
          'detalles': {actividadId: agendaItem}
        }, SetOptions(merge: true));
        print('Guardado en Firestore completado');

        // PROGRAMAR NOTIFICACIÓN
        if (recordatorioMinutos >= 0) { // Cambiar >= 1 por >= 0
          print('Programando notificación...');
          await _notificacionesService.programarRecordatorio(
            actividadId: actividadId,
            nombreActividad: actividad.nombre,
            zona: actividad.zona,
            fechaInicio: actividad.fechaInicio,
            minutosAntes: recordatorioMinutos,
          );
          print('Llamada a programarRecordatorio completada');
        } else {
          print('No se programa notificación (recordatorioMinutos < 0)');
        }
      }

      print('=== FIN DEBUG AGENDA SERVICE ===');
      return true;
    } catch (e) {
      print('ERROR en alternarActividadEnAgenda: $e');
      return false;
    }
  }
}