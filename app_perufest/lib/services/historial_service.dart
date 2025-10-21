import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_inicio.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class HistorialService {
  static final _registrosInicio = FirebaseFirestore.instance.collection('registrosiniciochambi');

  // Registrar un nuevo inicio de sesión
  static Future<void> registrarInicioSesion(String usuarioId) async {
    print('🚀 Iniciando registro de inicio de sesión para usuario: $usuarioId');
    try {
      final dispositivoInfo = _obtenerInfoDispositivo();
      print('📱 Dispositivo: $dispositivoInfo');
      
      final ip = await _obtenerIP(); // Obtener IP real
      print('🌐 IP final para guardar: ${ip ?? "null"}');
      
      final registro = RegistroInicio(
        id: '', // Se asigna automáticamente por Firestore
        usuarioId: usuarioId,
        fechaInicio: DateTime.now(),
        dispositivoInfo: dispositivoInfo,
        direccionIP: ip, // IP real o null si falla
      );

      print('💾 Guardando registro: ${registro.toJson()}');
      final docRef = await _registrosInicio.add(registro.toJson());
      print('✅ Registro de inicio guardado con ID: ${docRef.id}');
      if (ip != null) {
        print('🌐 Con IP: $ip');
      } else {
        print('⚠️ Sin IP capturada');
      }
    } catch (e) {
      print('❌ Error al registrar inicio de sesión: $e');
      print('❌ Stack trace: ${e.toString()}');
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

  // Obtener dirección IP pública con servicios alternativos
  static Future<String?> _obtenerIP() async {
    print('🔄 Intentando obtener IP...');
    
    // Lista de servicios para obtener IP
    final servicios = [
      'https://api.ipify.org',
      'https://httpbin.org/ip',
      'https://ipecho.net/plain',
    ];
    
    for (int i = 0; i < servicios.length; i++) {
      final servicio = servicios[i];
      print('🌐 Intentando con servicio ${i + 1}: $servicio');
      
      try {
        final response = await http.get(
          Uri.parse(servicio),
          headers: {'Content-Type': 'text/plain'},
        ).timeout(const Duration(seconds: 8));
        
        print('📡 Respuesta HTTP: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          String ip = response.body.trim();
          
          // Para httpbin.org/ip, la respuesta es JSON
          if (servicio.contains('httpbin')) {
            try {
              final jsonResponse = response.body;
              final match = RegExp(r'"origin":\s*"([^"]+)"').firstMatch(jsonResponse);
              if (match != null) {
                ip = match.group(1)!.split(',')[0].trim(); // Tomar solo la primera IP
              }
            } catch (e) {
              print('⚠️ Error parseando JSON de httpbin: $e');
              continue;
            }
          }
          
          if (ip.isNotEmpty && _esIPValida(ip)) {
            print('✅ IP obtenida exitosamente: $ip');
            return ip;
          } else {
            print('⚠️ IP inválida o vacía: $ip');
          }
        } else {
          print('❌ Error HTTP: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Error con servicio $servicio: $e');
        if (i < servicios.length - 1) {
          print('🔄 Intentando con siguiente servicio...');
        }
      }
    }
    
    print('🚫 No se pudo obtener IP de ningún servicio');
    return null;
  }

  // Validar si la IP tiene formato correcto
  static bool _esIPValida(String ip) {
    final ipRegex = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    return ipRegex.hasMatch(ip);
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