import 'package:cloud_firestore/cloud_firestore.dart';
class AgendaUsuario {
  final String id;
  final String userId;
  final String actividadId;
  final DateTime fechaAgregado;
  final String estado;
  final int recordatorioMinutos;
  AgendaUsuario({
    required this.id,
    required this.userId,
    required this.actividadId,
    required this.fechaAgregado,
    this.estado = 'confirmado',
    this.recordatorioMinutos = 30,
  });
  // Crear desde Firestore
  factory AgendaUsuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AgendaUsuario(
      id: doc.id,
      userId: data['userId'] ?? '',
      actividadId: data['actividadId'] ?? '',
      fechaAgregado: (data['fechaAgregado'] as Timestamp).toDate(),
      estado: data['estado'] ?? 'confirmado',
      recordatorioMinutos: data['recordatorioMinutos'] ?? 30,
    );
  }
  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'actividadId': actividadId,
      'fechaAgregado': Timestamp.fromDate(fechaAgregado),
      'estado': estado,
      'recordatorioMinutos': recordatorioMinutos,
    };
  }
}