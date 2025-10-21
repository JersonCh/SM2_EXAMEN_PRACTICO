import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/encriptacion_util.dart';

class AutenticacionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Inicia sesión del usuario
  /// [correo] - Email del usuario
  /// [contrasena] - Contraseña en texto plano
  /// Retorna datos del usuario si la autenticación es exitosa, null si falla
  Future<Map<String, dynamic>?> iniciarSesion(
    String correo,
    String contrasena,
  ) async {
    try {
      print('🔐 Iniciando sesión para: $correo');

      // Obtener usuario y su contraseña encriptada
      final usuario =
          await _supabase
              .from('usuarios')
              .select('id, nombre, correo, contrasena, rol, username, telefono')
              .eq('correo', correo)
              .maybeSingle();

      if (usuario == null) {
        print('❌ Usuario no encontrado');
        return null;
      }

      // 🔐 VERIFICAR CONTRASEÑA CON BCRYPT
      print('🔐 Verificando contraseña con bcrypt...');
      final contrasenaValida = EncriptacionUtil.verificarContrasena(
        contrasena,
        usuario['contrasena'],
      );

      if (!contrasenaValida) {
        print('❌ Contraseña incorrecta');
        return null;
      }

      print('✅ Autenticación exitosa');

      // Retornar datos del usuario (sin la contraseña)
      return {
        'id': usuario['id'],
        'nombre': usuario['nombre'],
        'correo': usuario['correo'],
        'rol': usuario['rol'],
        'username': usuario['username'],
        'telefono': usuario['telefono'],
      };
    } catch (e) {
      print('❌ Error en autenticación: $e');
      return null;
    }
  }

  /// Registra un nuevo usuario
  /// [nombre] - Nombre completo del usuario
  /// [username] - Nombre de usuario único
  /// [correo] - Email del usuario
  /// [telefono] - Teléfono del usuario
  /// [contrasena] - Contraseña en texto plano (se encriptará automáticamente)
  /// [rol] - Rol del usuario (por defecto 'usuario')
  /// Retorna true si el registro es exitoso
  Future<bool> registrarUsuario({
    required String nombre,
    required String username,
    required String correo,
    required String telefono,
    required String contrasena,
    String rol = 'usuario',
  }) async {
    try {
      print('🔐 Registrando nuevo usuario: $correo');

      // Verificar si el usuario ya existe
      final usuarioExistente =
          await _supabase
              .from('usuarios')
              .select('correo')
              .or('correo.eq.$correo,username.eq.$username')
              .maybeSingle();

      if (usuarioExistente != null) {
        print('❌ Usuario ya existe con ese correo o username');
        return false;
      }

      // 🔐 ENCRIPTAR CONTRASEÑA CON BCRYPT
      print('🔐 Encriptando contraseña con bcrypt...');
      final contrasenaEncriptada = EncriptacionUtil.hashContrasena(contrasena);
      print('✅ Contraseña encriptada generada');

      // Insertar usuario con contraseña encriptada
      await _supabase.from('usuarios').insert({
        'nombre': nombre,
        'username': username,
        'correo': correo,
        'telefono': telefono,
        'contrasena': contrasenaEncriptada, // Contraseña encriptada
        'rol': rol,
      });

      print('✅ Usuario registrado exitosamente con contraseña encriptada');
      return true;
    } catch (e) {
      print('❌ Error registrando usuario: $e');
      return false;
    }
  }

  /// Verifica si un correo ya está registrado
  Future<bool> correoExiste(String correo) async {
    try {
      final usuario =
          await _supabase
              .from('usuarios')
              .select('correo')
              .eq('correo', correo)
              .maybeSingle();

      return usuario != null;
    } catch (e) {
      print('❌ Error verificando correo: $e');
      return false;
    }
  }

  /// Verifica si un username ya está registrado
  Future<bool> usernameExiste(String username) async {
    try {
      final usuario =
          await _supabase
              .from('usuarios')
              .select('username')
              .eq('username', username)
              .maybeSingle();

      return usuario != null;
    } catch (e) {
      print('❌ Error verificando username: $e');
      return false;
    }
  }

  /// Actualiza contraseñas en texto plano a bcrypt
  Future<int> actualizarContrasenasABcrypt() async {
    try {
      print('🔄 Buscando contraseñas en texto plano...');

      final response = await _supabase
          .from('usuarios')
          .select('id, correo, contrasena');

      final usuarios = response as List<dynamic>;
      int actualizados = 0;

      for (final usuario in usuarios) {
        final contrasenaActual = usuario['contrasena'] as String;

        // Si la contraseña no parece un hash bcrypt (no empieza con $2)
        if (!contrasenaActual.startsWith('\$2')) {
          print('🔄 Actualizando contraseña para: ${usuario['correo']}');

          final hashNuevo = EncriptacionUtil.hashContrasena(contrasenaActual);

          await _supabase
              .from('usuarios')
              .update({'contrasena': hashNuevo})
              .eq('id', usuario['id']);

          print('✅ Hash actualizado para: ${usuario['correo']}');
          actualizados++;
        }
      }

      print(
        '✅ Actualización completada. $actualizados contraseñas actualizadas',
      );
      return actualizados;
    } catch (e) {
      print('❌ Error actualizando contraseñas: $e');
      return 0;
    }
  }
}
