class Valoracion {
  final String id;
  final String standId; // Referencia al stand valorado
  final String usuarioId; // Referencia al usuario que realiza la valoración
  final String nombreUsuario;
  final double puntuacion; // Valor numérico (1.0 - 5.0)
  final String comentario;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String estado; // 'activo', 'eliminado', 'pendiente'

  Valoracion({
    required this.id,
    required this.standId,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.puntuacion,
    required this.comentario,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.estado = 'activo',
  });

  factory Valoracion.fromJson(Map<String, dynamic> json) {
    return Valoracion(
      id: json['id'] ?? '',
      standId: json['stand_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      nombreUsuario: json['nombre_usuario'] ?? '',
      puntuacion: (json['puntuacion'] ?? 0).toDouble(),
      comentario: json['comentario'] ?? '',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : DateTime.now(),
      estado: json['estado'] ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stand_id': standId,
      'usuario_id': usuarioId,
      'nombre_usuario': nombreUsuario,
      'puntuacion': puntuacion,
      'comentario': comentario,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'estado': estado,
    };
  }

  Valoracion copyWith({
    String? id,
    String? standId,
    String? usuarioId,
    String? nombreUsuario,
    double? puntuacion,
    String? comentario,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? estado,
  }) {
    return Valoracion(
      id: id ?? this.id,
      standId: standId ?? this.standId,
      usuarioId: usuarioId ?? this.usuarioId,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      puntuacion: puntuacion ?? this.puntuacion,
      comentario: comentario ?? this.comentario,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      estado: estado ?? this.estado,
    );
  }

  @override
  String toString() {
    return 'Valoracion{id: $id, standId: $standId, puntuacion: $puntuacion, usuario: $nombreUsuario}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Valoracion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
