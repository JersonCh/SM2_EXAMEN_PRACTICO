import 'package:bcrypt/bcrypt.dart';

class EncriptacionUtil {
  /// Genera un hash bcrypt de la contraseña
  /// [contrasena] - La contraseña en texto plano
  /// Retorna el hash bcrypt de la contraseña
  static String hashContrasena(String contrasena) {
    print('🔐 Generando hash bcrypt para contraseña...');
    final hash = BCrypt.hashpw(contrasena, BCrypt.gensalt());
    print('✅ Hash bcrypt generado exitosamente');
    return hash;
  }

  /// Verifica si una contraseña coincide con su hash bcrypt
  /// [contrasena] - La contraseña en texto plano
  /// [hash] - El hash bcrypt almacenado en la base de datos
  /// Retorna true si la contraseña es correcta
  static bool verificarContrasena(String contrasena, String hash) {
    print('🔍 Verificando contraseña con hash bcrypt...');
    try {
      final esValida = BCrypt.checkpw(contrasena, hash);
      print(esValida ? '✅ Contraseña válida' : '❌ Contraseña inválida');
      return esValida;
    } catch (e) {
      print('❌ Error verificando contraseña: $e');
      return false;
    }
  }
}
