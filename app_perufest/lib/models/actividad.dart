import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/timezone.dart';

class Actividad {
  final String id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String zona;
  final String eventoId;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Actividad({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.zona,
    required this.eventoId,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  // Crear desde Firestore
  factory Actividad.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Actividad(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      zona: data['zona'] ?? '',
      eventoId: data['eventoId'] ?? '',
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'zona': zona,
      'eventoId': eventoId,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
    };
  }

  // Crear copia con cambios
  Actividad copyWith({
    String? id,
    String? nombre,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? zona,
    String? eventoId,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Actividad(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      zona: zona ?? this.zona,
      eventoId: eventoId ?? this.eventoId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

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

  // Check if activity is active based on Peru time
  bool get yaInicio {
    final ahoraPeru = TimezoneUtils.now();
    return ahoraPeru.isAfter(fechaInicioPeruana);
  }

  bool get yaTermino {
    final ahoraPeru = TimezoneUtils.now();
    return ahoraPeru.isAfter(fechaFinPeruana);
  }

  bool get estaEnCurso {
    final ahoraPeru = TimezoneUtils.now();
    return ahoraPeru.isAfter(fechaInicioPeruana) && ahoraPeru.isBefore(fechaFinPeruana);
  }

  // Getters útiles
  String get horaInicio {
    final inicio = fechaInicioPeruana;
    return '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
  }
  
  String get horaFin {
    final fin = fechaFinPeruana;
    return '${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}';
  }
  
  String get horario => '$horaInicio - $horaFin hrs.';
  
  Duration get duracionDuration => fechaFinPeruana.difference(fechaInicioPeruana);
  
  String get duracion {
    final dur = fechaFinPeruana.difference(fechaInicioPeruana);
    final horas = dur.inHours;
    final minutos = dur.inMinutes % 60;
    
    if (horas > 0 && minutos > 0) {
      return '${horas}h ${minutos}m';
    } else if (horas > 0) {
      return '${horas}h';
    } else if (minutos > 0) {
      return '${minutos}m';
    } else {
      return '< 1m';
    }
  }
  
  bool get esElMismoDia {
    final inicioPeruana = fechaInicioPeruana;
    final finPeruana = fechaFinPeruana;
    return inicioPeruana.day == finPeruana.day && 
           inicioPeruana.month == finPeruana.month && 
           inicioPeruana.year == finPeruana.year;
  }

  @override
  String toString() {
    return 'Actividad(id: $id, nombre: $nombre, zona: $zona, horario: $horario)';
  }
}