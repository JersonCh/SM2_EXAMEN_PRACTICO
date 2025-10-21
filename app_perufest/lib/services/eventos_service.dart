import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/evento.dart';
import '../services/timezone.dart';

class EventosService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'eventos';

  static Future<String> crearEvento(Evento evento) async {
    try {
      final now = TimezoneUtils.now(); // Use Peru timezone
      final eventoData = evento.copyWith(
        fechaCreacion: now,
        fechaActualizacion: now,
      ).toJson();

      final docRef = await _db.collection(_collection).add(eventoData);
      if (kDebugMode) {
        debugPrint('Evento creado con ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al crear evento: $e');
      }
      throw Exception('Error al crear el evento');
    }
  }

  static Future<List<Evento>> obtenerEventos() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('fechaInicio', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Evento.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener eventos: $e');
      }
      throw Exception('Error al cargar los eventos');
    }
  }

  static Future<List<Evento>> buscarEventos(String termino) async {
    try {
      final snapshot = await _db.collection(_collection).get();
      
      final eventos = snapshot.docs
          .map((doc) => Evento.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      return eventos.where((evento) {
        final terminoLower = termino.toLowerCase();
        return evento.nombre.toLowerCase().contains(terminoLower) ||
            evento.lugar.toLowerCase().contains(terminoLower) ||
            evento.organizador.toLowerCase().contains(terminoLower);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al buscar eventos: $e');
      }
      throw Exception('Error al buscar eventos');
    }
  }

  static Future<List<Evento>> filtrarEventosPorCategoria(String categoria) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('categoria', isEqualTo: categoria)
          .orderBy('fechaInicio', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Evento.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al filtrar eventos: $e');
      }
      throw Exception('Error al filtrar eventos');
    }
  }


  static Future<Evento?> obtenerEventoPorId(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      
      if (doc.exists && doc.data() != null) {
        return Evento.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener evento: $e');
      }
      throw Exception('Error al cargar el evento');
    }
  }

  static Future<void> actualizarEvento(String id, Evento evento) async {
    try {
      final eventoData = evento.copyWith(
        fechaActualizacion: TimezoneUtils.now(), // Use Peru timezone
      ).toJson();
      
      await _db.collection(_collection).doc(id).update(eventoData);
      
      if (kDebugMode) {
        debugPrint('Evento actualizado: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar evento: $e');
      }
      throw Exception('Error al actualizar el evento');
    }
  }

  static Future<void> eliminarEvento(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      
      if (kDebugMode) {
        debugPrint('Evento eliminado: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al eliminar evento: $e');
      }
      throw Exception('Error al eliminar el evento');
    }
  }

  static Future<void> actualizarEstadoEvento(String id, String nuevoEstado) async {
    try {
      await _db.collection(_collection).doc(id).update({
        'estado': nuevoEstado,
        'fechaActualizacion': TimezoneUtils.now().toIso8601String(), // Use Peru timezone
      });
      
      if (kDebugMode) {
        debugPrint('Estado del evento actualizado: $id -> $nuevoEstado');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar estado: $e');
      }
      throw Exception('Error al actualizar el estado del evento');
    }
  }
}