import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import 'package:bcrypt/bcrypt.dart';

class FirestoreService {
  static final _usuarios = FirebaseFirestore.instance.collection('usuarios');
  static final _comentarios = FirebaseFirestore.instance.collection(
    'comentarios',
  );

  static Future<void> registrarUsuario(Usuario usuario) async {
    final data = usuario.toJson();
    // Asegurar que no se incluya el campo password
    data.remove('password');
    final docRef = await _usuarios.add(data);
    print('📝 Usuario registrado con ID: ${docRef.id}');
  }

  static Future<Usuario?> loginUsuario(String correo, String contrasena) async {
    print('🔄 Intentando login para correo: $correo');
    final query =
        await _usuarios.where('correo', isEqualTo: correo).limit(1).get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      print('📄 Datos del usuario encontrados: $data');
      print('🆔 ID del documento: ${doc.id}');

      // Agregar el ID del documento a los datos
      data['id'] = doc.id;

      final usuario = Usuario.fromJson(data);
      print('👤 Usuario creado con ID: ${usuario.id}');
      print('🔐 Contraseña almacenada: ${usuario.contrasena}');
      print('🔑 Verificando contraseña con bcrypt...');
      final coincide = BCrypt.checkpw(contrasena, usuario.contrasena);
      print(coincide ? '✅ Contraseña correcta' : '❌ Contraseña incorrecta');
      if (coincide) {
        return usuario;
      }
    } else {
      print('❌ No se encontró usuario con el correo: $correo');
    }
    return null;
  }

  static Future<bool> correoExiste(String correo) async {
    final query =
        await _usuarios.where('correo', isEqualTo: correo).limit(1).get();
    return query.docs.isNotEmpty;
  }

  // Método para obtener usuario por ID
  static Future<Usuario?> obtenerUsuarioPorId(String userId) async {
    try {
      final doc = await _usuarios.doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Usuario.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario por ID: $e');
      return null;
    }
  }

  // Comentarios: listar por stand (públicos)
  static Future<List<Map<String, dynamic>>> obtenerComentariosPorStand(
    String standId,
  ) async {
    final query =
        await _comentarios
            .where('standId', isEqualTo: standId)
            .where('publico', isEqualTo: true)
            .orderBy('fecha', descending: true)
            .get();
    return query.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).toList();
  }

  static Future<String?> publicarComentario(
    Map<String, dynamic> comentarioData,
  ) async {
    try {
      final docRef = await _comentarios.add(comentarioData);
      return docRef.id;
    } catch (e) {
      print('Error al publicar comentario: $e');
      return null;
    }
  }

  static Future<bool> reportarComentario(String comentarioId) async {
    // Funcionalidad de reportes eliminada: no-op
    print(
      'reportarComentario() no está disponible. ComentarioId: $comentarioId',
    );
    return false;
  }

  // Marcar si un comentario fue útil (si/no)
  static Future<bool> marcarUtil(String comentarioId, String tipo) async {
    try {
      final docRef = _comentarios.doc(comentarioId);
      if (tipo == 'si') {
        await docRef.update({'utilSi': FieldValue.increment(1)});
      } else {
        await docRef.update({'utilNo': FieldValue.increment(1)});
      }
      return true;
    } catch (e) {
      print('Error al marcar util: $e');
      return false;
    }
  }

  // Método para limpiar el campo password de un usuario
  static Future<void> limpiarCampoPassword(String correo) async {
    print('🧹 Limpiando campo password para: $correo');
    final query =
        await _usuarios.where('correo', isEqualTo: correo).limit(1).get();
    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;
      await docRef.update({'password': FieldValue.delete()});
      print('✅ Campo password eliminado exitosamente');
    }
  }
}
