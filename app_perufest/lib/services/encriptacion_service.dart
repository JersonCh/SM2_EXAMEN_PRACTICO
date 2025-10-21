import 'package:bcrypt/bcrypt.dart';

class EncriptacionService {
  /// Encripta una contraseña usando bcrypt
  static String encriptarContrasena(String contrasena) {
    return BCrypt.hashpw(contrasena, BCrypt.gensalt());
  }

  /// Verifica si una contraseña coincide con su hash encriptado
  static bool verificarContrasena(String contrasena, String hashAlmacenado) {
    try {
      return BCrypt.checkpw(contrasena, hashAlmacenado);
    } catch (e) {
      // En caso de error al verificar el hash
      return false;
    }
  }
}
