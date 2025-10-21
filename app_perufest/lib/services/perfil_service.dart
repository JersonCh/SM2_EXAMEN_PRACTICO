import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilService {
  static final _usuarios = FirebaseFirestore.instance.collection('usuarios');

  // Obtener datos del usuario por ID
  static Future<Map<String, dynamic>?> obtenerDatosUsuario(
    String userId,
  ) async {
    try {
      final doc = await _usuarios.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Actualizar datos básicos del usuario
  static Future<bool> actualizarDatosBasicos(
    String userId,
    Map<String, dynamic> datos,
  ) async {
    try {
      // Remover campos que no deben ser editados
      datos.remove('email');
      datos.remove('correo');
      datos.remove('password');
      datos.remove('contrasena');
      datos.remove('id');

      // Limpiar campos duplicados si existen
      final updates = Map<String, dynamic>.from(datos);

      // Si estamos actualizando username, limpiar el campo usuario duplicado
      if (updates.containsKey('username')) {
        updates['usuario'] = FieldValue.delete();
      }

      // Si estamos actualizando telefono, limpiar el campo celular duplicado
      if (updates.containsKey('telefono')) {
        updates['celular'] = FieldValue.delete();
      }

      await _usuarios.doc(userId).update(updates);
      return true;
    } catch (e) {
      print('Error al actualizar datos básicos: $e');
      return false;
    }
  }

  // Agregar nueva red social (solo para expositores)
  static Future<bool> agregarRedSocial(
    String userId,
    String nombre,
    String url,
  ) async {
    try {
      await _usuarios.doc(userId).update({'redes_sociales.$nombre': url});
      return true;
    } catch (e) {
      print('Error al agregar red social: $e');
      return false;
    }
  }

  // Eliminar red social (solo para expositores)
  static Future<bool> eliminarRedSocial(String userId, String nombre) async {
    try {
      await _usuarios.doc(userId).update({
        'redes_sociales.$nombre': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      print('Error al eliminar red social: $e');
      return false;
    }
  }

  // Actualizar datos de empresa (solo para expositores)
  static Future<bool> actualizarDatosEmpresa(
    String userId,
    Map<String, dynamic> datosEmpresa,
  ) async {
    try {
      await _usuarios.doc(userId).update({'empresa': datosEmpresa});
      return true;
    } catch (e) {
      print('Error al actualizar datos de empresa: $e');
      return false;
    }
  }

  // Actualizar imagen de perfil del usuario
  static Future<bool> actualizarImagenPerfil(
    String userId,
    String urlImagen,
  ) async {
    try {
      if (urlImagen.isEmpty) {
        // Si la URL está vacía, eliminar el campo
        await _usuarios.doc(userId).update({'imagenPerfil': FieldValue.delete()});
      } else {
        // Actualizar con la nueva URL
        await _usuarios.doc(userId).update({'imagenPerfil': urlImagen});
      }
      return true;
    } catch (e) {
      print('Error al actualizar imagen de perfil: $e');
      return false;
    }
  }

  // Método para limpiar campos duplicados existentes
  static Future<bool> limpiarCamposDuplicados(String userId) async {
    try {
      final updates = <String, dynamic>{};

      // Obtener datos actuales
      final doc = await _usuarios.doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;

      // Si existen ambos campos duplicados, eliminar los antiguos
      if (data.containsKey('usuario') && data.containsKey('username')) {
        updates['usuario'] = FieldValue.delete();
        print('Eliminando campo duplicado: usuario');
      }

      if (data.containsKey('celular') && data.containsKey('telefono')) {
        updates['celular'] = FieldValue.delete();
        print('Eliminando campo duplicado: celular');
      }

      // Solo actualizar si hay campos que limpiar
      if (updates.isNotEmpty) {
        await _usuarios.doc(userId).update(updates);
        print('Campos duplicados limpiados exitosamente');
      }

      return true;
    } catch (e) {
      print('Error al limpiar campos duplicados: $e');
      return false;
    }
  }
}
