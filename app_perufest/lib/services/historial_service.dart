import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_inicio.dart';
import 'dart:io';

class HistorialService {
  static final _registrosInicio = FirebaseFirestore.instance.collection('registrosiniciochambi');

  // Registrar un nuevo inicio de sesión
  static Future<void> registrarInicioSesion(String usuarioId) async {
    try {
      final dispositivoInfo = _obtenerInfoDispositivo();
      
      final registro = RegistroInicio(
        id: '', // Se asigna automáticamente por Firestore
        usuarioId: usuarioId,
        fechaInicio: DateTime.now(),
        dispositivoInfo: dispositivoInfo,
        direccionIP: null, // Opcional para móviles
      );

      final docRef = await _registrosInicio.add(registro.toJson());
      print('📝 Registro de inicio guardado con ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error al registrar inicio de sesión: $e');
    }
  }

  // Obtener historial de un usuario específico
  static Future<List<RegistroInicio>> obtenerHistorialUsuario(String usuarioId) async {
    try {
      final query = await _registrosInicio
          .where('usuarioId', isEqualTo: usuarioId)
          .orderBy('fechaInicio', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RegistroInicio.fromJson(data);
      }).toList();
    } catch (e) {
      print('❌ Error al obtener historial: $e');
      return [];
    }
  }

  // Obtener información del dispositivo
  static String _obtenerInfoDispositivo() {
    try {
      if (Platform.isAndroid) {
        return 'Dispositivo Android';
      } else if (Platform.isIOS) {
        return 'Dispositivo iOS';
      } else if (Platform.isWindows) {
        return 'Dispositivo Windows';
      } else if (Platform.isMacOS) {
        return 'Dispositivo macOS';
      } else if (Platform.isLinux) {
        return 'Dispositivo Linux';
      }
      
      return 'Dispositivo ${Platform.operatingSystem}';
    } catch (e) {
      return 'Dispositivo desconocido';
    }
  }

  // Limpiar registros antiguos (opcional - más de 90 días)
  static Future<void> limpiarRegistrosAntiguos() async {
    try {
      final fechaLimite = DateTime.now().subtract(const Duration(days: 90));
      final query = await _registrosInicio
          .where('fechaInicio', isLessThan: fechaLimite.toIso8601String())
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
      
      print('🧹 Limpieza de registros antiguos completada: ${query.docs.length} eliminados');
    } catch (e) {
      print('❌ Error al limpiar registros antiguos: $e');
    }
  }
}