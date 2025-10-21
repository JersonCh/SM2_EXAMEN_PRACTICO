import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/zona_mapa.dart';
import '../services/timezone.dart';

class ZonasService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'zonas';

  // Crear una nueva zona
  static Future<String> crearZona(ZonaMapa zona) async {
    try {
      final now = TimezoneUtils.now();
      final zonaData = zona.copyWith(
        fechaCreacion: now,
        fechaActualizacion: now,
      ).toJson();

      final docRef = await _db.collection(_collection).add(zonaData);
      if (kDebugMode) {
        debugPrint('Zona creada con ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al crear zona: $e');
      }
      throw Exception('Error al crear la zona');
    }
  }

  // Obtener todas las zonas de un evento específico
  static Future<List<ZonaMapa>> obtenerZonasPorEvento(String eventoId) async {
    try {
      if (kDebugMode) {
        debugPrint('Obteniendo zonas para evento: $eventoId');
      }

      final snapshot = await _db
          .collection(_collection)
          .where('eventoId', isEqualTo: eventoId)
          .get();

      if (kDebugMode) {
        debugPrint('Documentos encontrados: ${snapshot.docs.length}');
      }

      final zonas = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          if (kDebugMode) {
            debugPrint('Datos del documento ${doc.id}: $data');
          }
          return ZonaMapa.fromJson({
            'id': doc.id,
            ...data,
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error al procesar documento ${doc.id}: $e');
          }
          rethrow;
        }
      }).toList();

      if (kDebugMode) {
        debugPrint('Zonas procesadas correctamente: ${zonas.length}');
      }

      return zonas;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener zonas: $e');
      }
      throw Exception('Error al cargar las zonas');
    }
  }

  // Actualizar una zona existente
  static Future<void> actualizarZona(String id, ZonaMapa zona) async {
    try {
      final zonaData = zona.copyWith(
        fechaActualizacion: TimezoneUtils.now(),
      ).toJson();
      
      await _db.collection(_collection).doc(id).update(zonaData);
      
      if (kDebugMode) {
        debugPrint('Zona actualizada: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar zona: $e');
      }
      throw Exception('Error al actualizar la zona');
    }
  }

  // Eliminar una zona
  static Future<void> eliminarZona(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      
      if (kDebugMode) {
        debugPrint('Zona eliminada: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al eliminar zona: $e');
      }
      throw Exception('Error al eliminar la zona');
    }
  }

  // Eliminar todas las zonas de un evento
  static Future<void> eliminarZonasPorEvento(String eventoId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('eventoId', isEqualTo: eventoId)
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        debugPrint('Zonas eliminadas para el evento: $eventoId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al eliminar zonas del evento: $e');
      }
      throw Exception('Error al eliminar las zonas del evento');
    }
  }
}