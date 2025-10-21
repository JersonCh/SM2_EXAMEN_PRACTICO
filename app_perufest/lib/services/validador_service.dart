class ValidadorService {
  // Validar correo electrónico
  static String? validarCorreo(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'El correo es requerido';
    }

    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(valor)) {
      return 'Correo inválido';
    }

    return null;
  }

  // Validar contraseña
  static String? validarContrasena(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (valor.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // Validar confirmación de contraseña
  static String? validarConfirmarContrasena(String? valor, String contrasena) {
    if (valor == null || valor.isEmpty) {
      return 'Confirmar contraseña es requerido';
    }
    if (valor != contrasena) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Validar campo requerido
  static String? validarCampoRequerido(String? valor, String nombreCampo) {
    if (valor == null || valor.isEmpty) {
      return '$nombreCampo es requerido';
    }
    return null;
  }

  // Validar nombre (solo letras y espacios)
  static String? validarNombre(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'El nombre es requerido';
    }

    final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!regex.hasMatch(valor)) {
      return 'El nombre solo puede contener letras';
    }

    return null;
  }

  // Validar username (alfanumérico y guiones bajos)
  static String? validarUsername(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'El username es requerido';
    }

    if (valor.length < 3) {
      return 'El username debe tener al menos 3 caracteres';
    }

    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(valor)) {
      return 'El username solo puede contener letras, números y _';
    }

    return null;
  }

  // Validar teléfono
  static String? validarTelefono(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'El teléfono es requerido';
    }

    final regex = RegExp(r'^[0-9]{9,15}$');
    if (!regex.hasMatch(valor)) {
      return 'Teléfono inválido (9-15 dígitos)';
    }

    return null;
  }
}
