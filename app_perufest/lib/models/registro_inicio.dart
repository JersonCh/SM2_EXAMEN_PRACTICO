class RegistroInicio {
  final String id;
  final String usuarioId;
  final DateTime fechaInicio;
  final String dispositivoInfo;
  final String? direccionIP;

  RegistroInicio({
    required this.id,
    required this.usuarioId,
    required this.fechaInicio,
    required this.dispositivoInfo,
    this.direccionIP,
  });

  factory RegistroInicio.fromJson(Map<String, dynamic> json) {
    return RegistroInicio(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuarioId']?.toString() ?? '',
      fechaInicio: json['fechaInicio'] != null 
          ? DateTime.parse(json['fechaInicio'].toString())
          : DateTime.now(),
      dispositivoInfo: json['dispositivoInfo'] ?? 'Dispositivo desconocido',
      direccionIP: json['direccionIP'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'fechaInicio': fechaInicio.toIso8601String(),
      'dispositivoInfo': dispositivoInfo,
      'direccionIP': direccionIP,
    };
  }

  @override
  String toString() {
    return 'RegistroInicio(id: $id, usuarioId: $usuarioId, fechaInicio: $fechaInicio)';
  }
}