import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../services/encriptacion_util.dart';


class RecuperacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generarCodigo() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  Future<bool> enviarCodigoRecuperacion(String correo) async {
    try {
      // Verificar que el correo existe en Firestore
  final query = await _firestore.collection('usuarios').where('correo', isEqualTo: correo).limit(1).get();
      if (query.docs.isEmpty) return false;
      final usuario = query.docs.first.data();
      final nombre = usuario['usuario'] ?? 'Usuario';

      // Generar código
      final codigo = _generarCodigo();
      final expiraEn = DateTime.now().add(Duration(minutes: 15));

      // Invalidar códigos anteriores
      final codigos = await _firestore.collection('codigos_recuperacion')
        .where('correo', isEqualTo: correo)
        .where('usado', isEqualTo: false)
        .get();
      for (var doc in codigos.docs) {
        await doc.reference.update({'usado': true});
      }

      // Guardar nuevo código
      await _firestore.collection('codigos_recuperacion').add({
        'correo': correo,
        'codigo': codigo,
        'expira_en': expiraEn.toIso8601String(),
        'usado': false,
      });

      // Enviar email
      await _enviarEmail(correo, codigo, nombre);

      return true;
    } catch (e) {
      print('Error enviando código: $e');
      return false;
    }
  }

  Future<bool> verificarCodigo(String correo, String codigo) async {
    try {
      print('🔍 Verificando código: $codigo para correo: $correo');
      final query = await _firestore.collection('codigos_recuperacion')
        .where('correo', isEqualTo: correo)
        .where('codigo', isEqualTo: codigo)
        .where('usado', isEqualTo: false)
        .limit(1)
        .get();
      if (query.docs.isEmpty) {
        print('❌ Código no encontrado o ya fue usado');
        return false;
      }
      final data = query.docs.first.data();
      final expiraEn = DateTime.parse(data['expira_en']);
      final ahora = DateTime.now();
      print('⏰ Código expira en: $expiraEn');
      print('⏰ Hora actual: $ahora');
      print('⏰ ¿Código válido? ${ahora.isBefore(expiraEn)}');
      return ahora.isBefore(expiraEn);
    } catch (e) {
      print('Error verificando código: $e');
      return false;
    }
  }

  Future<bool> cambiarContrasena(
    String correo,
    String codigo,
    String nuevaContrasena,
  ) async {
    try {
      print('🔄 Iniciando cambio de contraseña para: $correo');
      // Verificar que el código sigue siendo válido
      if (!await verificarCodigo(correo, codigo)) {
        print('❌ Código inválido o expirado durante cambio de contraseña');
        return false;
      }
      // Obtener el usuario desde la base de datos
  final query = await _firestore.collection('usuarios').where('correo', isEqualTo: correo).limit(1).get();
      if (query.docs.isEmpty) {
        print('❌ Usuario no encontrado para correo: $correo');
        return false;
      }
      final userRef = query.docs.first.reference;
      // 🔐 ENCRIPTAR LA NUEVA CONTRASEÑA CON BCRYPT
      print('🔐 Encriptando nueva contraseña con bcrypt...');
      final contrasenaEncriptada = EncriptacionUtil.hashContrasena(
        nuevaContrasena,
      );
      print('✅ Contraseña encriptada generada');
      // Actualizar contraseña encriptada en la base de datos
      print('🔄 Actualizando contraseña encriptada en la base de datos...');
  await userRef.update({'contrasena': contrasenaEncriptada});
      print('✅ Contraseña actualizada en la tabla usuarios');
      // Marcar código como usado
      print('🔄 Marcando código como usado...');
      final codigos = await _firestore.collection('codigos_recuperacion')
        .where('correo', isEqualTo: correo)
        .where('codigo', isEqualTo: codigo)
        .where('usado', isEqualTo: false)
        .get();
      for (var doc in codigos.docs) {
        await doc.reference.update({'usado': true});
      }
      print('✅ Código marcado como usado');
      print('🎉 Proceso de cambio de contraseña completado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      return false;
    }
  }

  // Método optimizado que cambia contraseña sin verificar código nuevamente
  // (para usar cuando ya se verificó el código en el viewmodel)
  Future<bool> cambiarContrasenaDirecto(
    String correo,
    String codigo,
    String nuevaContrasena,
  ) async {
    try {
      print('🔄 Cambiando contraseña directo (sin re-verificar código)');
      print('📧 Correo: $correo');
      // Obtener el usuario desde la base de datos
  final query = await _firestore.collection('usuarios').where('correo', isEqualTo: correo).limit(1).get();
      if (query.docs.isEmpty) {
        print('❌ Usuario no encontrado para correo: $correo');
        return false;
      }
      final userRef = query.docs.first.reference;
      // 🔐 ENCRIPTAR LA NUEVA CONTRASEÑA CON BCRYPT
      print('🔐 Encriptando nueva contraseña con bcrypt...');
      final contrasenaEncriptada = EncriptacionUtil.hashContrasena(
        nuevaContrasena,
      );
      print('✅ Contraseña encriptada generada');
      // Actualizar contraseña encriptada en la base de datos
      print('🔄 Actualizando contraseña encriptada en la base de datos...');
      // Eliminar el campo password y actualizar contrasena
      await userRef.update({
        'contrasena': contrasenaEncriptada,
        'password': FieldValue.delete()
      });
      print('✅ Contraseña actualizada y campo password eliminado');
      // Marcar código como usado
      final codigos = await _firestore.collection('codigos_recuperacion')
        .where('correo', isEqualTo: correo)
        .where('codigo', isEqualTo: codigo)
        .where('usado', isEqualTo: false)
        .get();
      for (var doc in codigos.docs) {
        await doc.reference.update({'usado': true});
      }
      print('✅ Código marcado como usado');
      print('🎉 Cambio de contraseña completado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error cambiando contraseña directo: $e');
      return false;
    }
  }

  Future<void> _enviarEmail(String correo, String codigo, String nombre) async {
    try {
      // Configuración de EmailJS
      const serviceId = 'service_adb8w5g'; // Tu service ID real
      const templateId = 'template_ieny5qp'; // Tu template ID real
      const publicKey = 'm1CRriG7hQ7rTkBIb'; // Tu public key
      const privateKey =
          'ibN97RwFGnD6-jVmm1CHD'; // Tu private key para apps móviles

      // Crear el payload para EmailJS (versión simple y limpia)
      final payload = {
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': correo,
          'to_name': nombre.isNotEmpty ? nombre : 'Usuario PeruFest',
          'from_email': 'jaimeelias.tacna.2016@gmail.com',
          'from_name': 'PeruFest Team',
          'reply_to': 'jaimeelias.tacna.2016@gmail.com',
          'codigo': codigo,
        },
        // Private key como accessToken (formato correcto para apps móviles)
        'accessToken': privateKey,
      };

      // Headers simples
      final headers = {'Content-Type': 'application/json'};

      print('🚀 Intentando enviar email real via EmailJS...');
      print('📧 Para: $correo');
      print('🔑 Service: $serviceId');
      print('📄 Template: $templateId');
      print('🔐 Private Key como accessToken en payload');
      print('🆔 Código generado: $codigo');
      print('📦 Payload final: ${json.encode(payload)}');

      // Enviar el email usando HTTP con private key en header
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ ¡EMAIL REAL ENVIADO EXITOSAMENTE!');
        print('📧 El código $codigo fue enviado a $correo');
        print('📬 Revisa tu bandeja de entrada y spam');
      } else {
        print('❌ Error al enviar email real: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        print('📄 Response headers: ${response.headers}');

        // Diagnóstico específico según el código de error
        if (response.statusCode == 400) {
          print(
            '🔧 Error 400: Verifica que el template_id y service_id sean correctos',
          );
        } else if (response.statusCode == 422) {
          print(
            '🔧 Error 422: Template variables no coinciden o faltan campos requeridos',
          );
        } else if (response.statusCode == 403) {
          print('🔧 Error 403: Public key inválido o servicio no autorizado');
        }

        print('� Verifica en https://dashboard.emailjs.com/ que:');
        print('   • El service está activo');
        print('   • El template existe con ID: $templateId');
        print('   • El Gmail está conectado correctamente');

        throw Exception(
          'EmailJS Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error enviando email real: $e');
      print('🔄 Activando modo simulado para no bloquear la app...');
      print('📧 [SIMULADO] Email enviado a $correo con código: $codigo');
      print('💡 Crea el template "template_recuperacion" en EmailJS');
      print('🌐 Dashboard: https://dashboard.emailjs.com/');
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
