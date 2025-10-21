import '../services/timezone.dart';
class Evento {
  final String id;
  final String nombre;
  final String descripcion;
  final String organizador;
  final String categoria;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String lugar;
  final String imagenUrl;
  final String creadoPor;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Evento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.organizador,
    required this.categoria,
    required this.fechaInicio,
    required this.fechaFin,
    required this.lugar,
    required this.imagenUrl,
    required this.creadoPor,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  // Add getters for Peru timezone
  DateTime get fechaInicioPeruana {
    return TimezoneUtils.toPeru(fechaInicio);
  }

  DateTime get fechaFinPeruana {
    return TimezoneUtils.toPeru(fechaFin);
  }

  DateTime get fechaCreacionPeruana {
    return TimezoneUtils.toPeru(fechaCreacion);
  }

  DateTime get fechaActualizacionPeruana {
    return TimezoneUtils.toPeru(fechaActualizacion);
  }

  // Add useful getters for display
  String get fechaInicioFormateada {
    final fecha = fechaInicioPeruana;
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String get fechaFinFormateada {
    final fecha = fechaFinPeruana;
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String get horaInicioFormateada {
    final fecha = fechaInicioPeruana;
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String get horaFinFormateada {
    final fecha = fechaFinPeruana;
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String get duracionFormateada {
    final duracion = fechaFinPeruana.difference(fechaInicioPeruana);
    final dias = duracion.inDays;
    
    if (dias == 0) {
      return 'Mismo día';
    } else if (dias == 1) {
      return '1 día';
    } else {
      return '$dias días';
    }
  }

  // Check if event is active based on Peru time
  bool get estaActivo {
    final ahoraPeru = TimezoneUtils.now();
    return ahoraPeru.isBefore(fechaFinPeruana) && estado == 'activo';
  }

  bool get yaTermino {
    final ahoraPeru = TimezoneUtils.now();
    return ahoraPeru.isAfter(fechaFinPeruana);
  }

  bool get yaEmpezo{
    final ahoraPeru = TimezoneUtils.now();
    return ahoraPeru.isAfter(fechaInicioPeruana);
  }

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      organizador: json['organizador'] ?? '',
      categoria: json['categoria'] ?? '',
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      lugar: json['lugar'] ?? '',
      imagenUrl: json['imagenUrl'] ?? '',
      creadoPor: json['creadoPor'] ?? '',
      estado: json['estado'] ?? 'activo',
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'organizador': organizador,
      'categoria': categoria,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'lugar': lugar,
      'imagenUrl': imagenUrl,
      'creadoPor': creadoPor,
      'estado': estado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  // Método para crear una copia con cambios
  Evento copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? organizador,
    String? categoria,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? lugar,
    String? imagenUrl,
    String? creadoPor,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Evento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      organizador: organizador ?? this.organizador,
      categoria: categoria ?? this.categoria,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      lugar: lugar ?? this.lugar,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      creadoPor: creadoPor ?? this.creadoPor,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  String toString() {
    return 'Evento(id: $id, nombre: $nombre, categoria: $categoria, estado: $estado)';
  }
}