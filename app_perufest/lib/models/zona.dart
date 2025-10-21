class Zona {
  final int numero;
  final String nombre;
  final String descripcion;

  const Zona({
    required this.numero,
    required this.nombre,
    required this.descripcion,
  });

  @override
  String toString() => nombre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Zona &&
          runtimeType == other.runtimeType &&
          numero == other.numero;

  @override
  int get hashCode => numero.hashCode;
}

class ZonasParque {
  static const List<Zona> todasLasZonas = [
    Zona(numero: 1, nombre: 'Plaza principal', descripcion: 'Área central del parque para eventos principales'),
    Zona(numero: 8, nombre: 'Zona comercial', descripcion: 'Área destinada a actividades comerciales y ventas'),
    Zona(numero: 9, nombre: 'Zona de discotecas', descripcion: 'Espacio para eventos nocturnos y música'),
    Zona(numero: 10, nombre: 'Patio de comidas', descripcion: 'Área gastronómica y restaurantes'),
    Zona(numero: 11, nombre: 'Plaza de toros', descripcion: 'Espacio para espectáculos taurinos y culturales'),
    Zona(numero: 12, nombre: 'Coliseo de gallos', descripcion: 'Área para espectáculos tradicionales'),
    Zona(numero: 13, nombre: 'Zona de juzgamiento', descripcion: 'Área para concursos y evaluaciones'),
    Zona(numero: 14, nombre: 'Zona artesanal', descripcion: 'Espacio para exhibición y venta de artesanías'),
    Zona(numero: 15, nombre: 'Juegos mecánicos', descripcion: 'Área de entretenimiento y diversiones'),
    Zona(numero: 16, nombre: 'Zona de vinos y piscos', descripcion: 'Área especializada en bebidas regionales'),
    Zona(numero: 17, nombre: 'Zona de parrillas', descripcion: 'Espacio para preparación de comidas a la parrilla'),
    Zona(numero: 18, nombre: 'Casona tacneña', descripcion: 'Edificación tradicional para eventos culturales'),
    Zona(numero: 19, nombre: 'Zona de comida rápida', descripcion: 'Área de servicios gastronómicos rápidos'),
    Zona(numero: 20, nombre: 'Zona de espectáculos', descripcion: 'Espacio destinado a presentaciones y shows'),
  ];

  // Obtener zona por nombre
  static Zona? obtenerPorNombre(String nombre) {
    try {
      return todasLasZonas.firstWhere((zona) => zona.nombre == nombre);
    } catch (e) {
      return null;
    }
  }

  // Obtener zona por número
  static Zona? obtenerPorNumero(int numero) {
    try {
      return todasLasZonas.firstWhere((zona) => zona.numero == numero);
    } catch (e) {
      return null;
    }
  }

  // Obtener solo los nombres para dropdown
  static List<String> obtenerNombres() {
    return todasLasZonas.map((zona) => zona.nombre).toList();
  }

  // Validar si existe la zona
  static bool existeZona(String nombre) {
    return todasLasZonas.any((zona) => zona.nombre == nombre);
  }
}