class Stand {
  final String id;
  final String nombreEmpresa;
  final String descripcion;
  final String imagenUrl;
  final String eventoId;
  final int zonaNumero;
  final String zonaNombre;
  final List<String> productos; // Lista de productos/platos que ofrece
  final String contacto;
  final String telefono;
  final String estado; // 'activo', 'inactivo', 'pendiente'
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Stand({
    required this.id,
    required this.nombreEmpresa,
    required this.descripcion,
    required this.imagenUrl,
    required this.eventoId,
    required this.zonaNumero,
    required this.zonaNombre,
    this.productos = const [],
    required this.contacto,
    required this.telefono,
    this.estado = 'activo',
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Stand.fromJson(Map<String, dynamic> json) {
    return Stand(
      id: json['id'] ?? '',
      nombreEmpresa: json['nombre_empresa'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagenUrl: json['imagen_url'] ?? '',
      eventoId: json['evento_id'] ?? '',
      zonaNumero: json['zona_numero'] ?? 0,
      zonaNombre: json['zona_nombre'] ?? '',
      productos: json['productos'] != null 
          ? List<String>.from(json['productos']) 
          : [],
      contacto: json['contacto'] ?? '',
      telefono: json['telefono'] ?? '',
      estado: json['estado'] ?? 'activo',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_empresa': nombreEmpresa,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
      'evento_id': eventoId,
      'zona_numero': zonaNumero,
      'zona_nombre': zonaNombre,
      'productos': productos,
      'contacto': contacto,
      'telefono': telefono,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  Stand copyWith({
    String? id,
    String? nombreEmpresa,
    String? descripcion,
    String? imagenUrl,
    String? eventoId,
    int? zonaNumero,
    String? zonaNombre,
    List<String>? productos,
    String? contacto,
    String? telefono,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Stand(
      id: id ?? this.id,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      eventoId: eventoId ?? this.eventoId,
      zonaNumero: zonaNumero ?? this.zonaNumero,
      zonaNombre: zonaNombre ?? this.zonaNombre,
      productos: productos ?? this.productos,
      contacto: contacto ?? this.contacto,
      telefono: telefono ?? this.telefono,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  String toString() {
    return 'Stand{id: $id, nombreEmpresa: $nombreEmpresa, zona: $zonaNombre}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stand &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}