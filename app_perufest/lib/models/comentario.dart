import 'package:cloud_firestore/cloud_firestore.dart';

class Comentario {
  final String id;
  final String standId;
  final String userId;
  final String userName;
  final String texto;
  final int estrellas; // 1-5
  final DateTime fecha;
  final int utilSi;
  final int utilNo;
  final bool publico;

  Comentario({
    required this.id,
    required this.standId,
    required this.userId,
    required this.userName,
    required this.texto,
    required this.estrellas,
    required this.fecha,
    this.utilSi = 0,
    this.utilNo = 0,
    // reportado field removed
    this.publico = true,
  });

  factory Comentario.fromJson(Map<String, dynamic> json, String id) {
    final fechaField = json['fecha'];
    DateTime fecha = DateTime.now();
    if (fechaField != null) {
      if (fechaField is Timestamp) {
        fecha = fechaField.toDate();
      } else if (fechaField is String) {
        fecha = DateTime.parse(fechaField);
      }
    }
    int parseIntSafe(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      if (v is String) {
        final i = int.tryParse(v);
        if (i != null) return i;
        final d = double.tryParse(v);
        if (d != null) return d.toInt();
        return 0;
      }
      return 0;
    }

    final estrellasRaw = json['estrellas'] ?? json['rating'];
    final utilSiRaw = json['utilSi'] ?? json['util_si'];
    final utilNoRaw = json['utilNo'] ?? json['util_no'];

    return Comentario(
      id: id,
      standId: json['standId'] ?? json['stand_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? 'anon',
      userName: json['userName'] ?? json['user_name'] ?? 'Anónimo',
      texto: json['texto'] ?? json['comentario'] ?? '',
      estrellas: parseIntSafe(estrellasRaw),
      fecha: fecha,
      utilSi: parseIntSafe(utilSiRaw),
      utilNo: parseIntSafe(utilNoRaw),
      publico: json['publico'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standId': standId,
      'userId': userId,
      'userName': userName,
      'texto': texto,
      'estrellas': estrellas,
      'fecha': Timestamp.fromDate(fecha),
      'utilSi': utilSi,
      'utilNo': utilNo,
      'publico': publico,
    };
  }
}
