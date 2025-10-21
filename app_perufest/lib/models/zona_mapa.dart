import 'package:latlong2/latlong.dart';

class ZonaMapa {
  final String id;
  final String nombre;
  final String eventoId;
  final LatLng ubicacion;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  ZonaMapa({
    required this.id,
    required this.nombre,
    required this.eventoId,
    required this.ubicacion,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory ZonaMapa.fromJson(Map<String, dynamic> json) {
    return ZonaMapa(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      eventoId: json['eventoId'] ?? '',
      ubicacion: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0.0,
        (json['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'eventoId': eventoId,
      'latitude': ubicacion.latitude,
      'longitude': ubicacion.longitude,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  ZonaMapa copyWith({
    String? id,
    String? nombre,
    String? eventoId,
    LatLng? ubicacion,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ZonaMapa(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      eventoId: eventoId ?? this.eventoId,
      ubicacion: ubicacion ?? this.ubicacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}