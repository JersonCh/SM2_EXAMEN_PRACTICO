import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comentario.dart';

class ComentariosViewModel extends ChangeNotifier {
  // Mapa: comentarioId -> { userId: 'si'|'no' }
  final Map<String, Map<String, String>> votosPorComentarioUsuario = {};

  // Obtener el voto actual del usuario para un comentario
  String? getVotoUsuario(String comentarioId, String userId) {
    return votosPorComentarioUsuario[comentarioId]?[userId];
  }

  // Marcar voto único y actualizar contadores correctamente
  Future<bool> marcarVotoUnico(
    String comentarioId,
    String userId,
    String nuevoVoto,
    String? votoAnterior,
  ) async {
    try {
      final docRef = _firestore.collection('comentarios').doc(comentarioId);
      final doc = await docRef.get();
      if (!doc.exists) return false;
      // Actualizar subcampo votos: {userId: nuevoVoto}
      await docRef.set({
        'votos': {userId: nuevoVoto},
      }, SetOptions(merge: true));
      // Ajustar contadores utilSi/utilNo SOLO si es primer voto o cambio de voto
      Map<String, dynamic> updates = {};
      if (votoAnterior == null) {
        // Primer voto
        if (nuevoVoto == 'si') updates['utilSi'] = FieldValue.increment(1);
        if (nuevoVoto == 'no') updates['utilNo'] = FieldValue.increment(1);
      } else if (votoAnterior != nuevoVoto) {
        // Cambio de voto
        if (nuevoVoto == 'si') {
          updates['utilSi'] = FieldValue.increment(1);
          updates['utilNo'] = FieldValue.increment(-1);
        } else {
          updates['utilSi'] = FieldValue.increment(-1);
          updates['utilNo'] = FieldValue.increment(1);
        }
      }
      // Si el voto es igual, NO actualizar contadores
      if (updates.isNotEmpty) await docRef.update(updates);
      // Actualizar en memoria
      votosPorComentarioUsuario.putIfAbsent(comentarioId, () => {});
      votosPorComentarioUsuario[comentarioId]![userId] = nuevoVoto;
      // Actualizar lista local de comentarios
      final idx = _comentarios.indexWhere((c) => c.id == comentarioId);
      if (idx != -1) {
        final c = _comentarios[idx];
        _comentarios[idx] = Comentario(
          id: c.id,
          standId: c.standId,
          userId: c.userId,
          userName: c.userName,
          texto: c.texto,
          estrellas: c.estrellas,
          fecha: c.fecha,
          utilSi:
              updates['utilSi'] == null
                  ? c.utilSi
                  : (nuevoVoto == 'si'
                      ? c.utilSi + 1
                      : (votoAnterior == 'si' ? c.utilSi - 1 : c.utilSi)),
          utilNo:
              updates['utilNo'] == null
                  ? c.utilNo
                  : (nuevoVoto == 'no'
                      ? c.utilNo + 1
                      : (votoAnterior == 'no' ? c.utilNo - 1 : c.utilNo)),
          publico: c.publico,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al marcar voto único: $e';
      notifyListeners();
      return false;
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Comentario> _comentarios = [];
  bool _isLoading = false;
  String _error = '';
  String? _currentStandId;

  List<Comentario> get comentarios => _comentarios;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> cargarComentariosPorStand(String standId) async {
    _currentStandId = standId;
    _comentarios = [];
    _isLoading = true;
    _error = '';
    // No notificar aquí; solo cuando termina la carga o hay error

    try {
      final col = _firestore.collection('comentarios');
      final q1 =
          await col
              .where('standId', isEqualTo: standId)
              .where('publico', isEqualTo: true)
              .orderBy('fecha', descending: true)
              .get();

      final q2 =
          await col
              .where('stand_id', isEqualTo: standId)
              .where('publico', isEqualTo: true)
              .orderBy('fecha', descending: true)
              .get();

      final Map<String, DocumentSnapshot> docsById = {};
      for (final d in q1.docs) docsById[d.id] = d;
      for (final d in q2.docs) docsById[d.id] = d;

      final merged = docsById.values.toList();

      _comentarios =
          merged
              .map(
                (d) =>
                    Comentario.fromJson(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();

      _isLoading = false;

      // Notificar cambios después de cargar datos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _error = 'Error al cargar comentarios: $e';
      _comentarios = [];
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<bool> publicarComentario(Comentario comentario) async {
    try {
      final data = comentario.toJson();
      // Use server timestamp to avoid timezone/clock differences between client and server
      data['fecha'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('comentarios').add(data);

      // Leer el documento guardado para obtener la fecha real asignada por el servidor
      final saved = await docRef.get();
      final savedData = saved.data() ?? {};
      final nuevo = Comentario.fromJson(
        Map<String, dynamic>.from(savedData),
        docRef.id,
      );

      // Sólo insertamos en la lista si corresponde al stand actualmente cargado
      if (_currentStandId == null || nuevo.standId == _currentStandId) {
        _comentarios.insert(0, nuevo);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al publicar comentario: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportarComentario(String comentarioId) async {
    // Reportar eliminado; use marcarUtil para marcar si fue útil o no.
    _error = 'Funcionalidad de reportes eliminada';
    notifyListeners();
    return false;
  }

  Future<bool> marcarUtil(String comentarioId, String tipo) async {
    try {
      // Llamamos al servicio que hace el incremento atómico
      final success = await _firestore
          .collection('comentarios')
          .doc(comentarioId)
          .get()
          .then((doc) async {
            if (!doc.exists) return false;
            if (tipo == 'si') {
              await doc.reference.update({'utilSi': FieldValue.increment(1)});
            } else {
              await doc.reference.update({'utilNo': FieldValue.increment(1)});
            }
            return true;
          });

      if (success) {
        final idx = _comentarios.indexWhere((c) => c.id == comentarioId);
        if (idx != -1) {
          final c = _comentarios[idx];
          _comentarios[idx] = Comentario(
            id: c.id,
            standId: c.standId,
            userId: c.userId,
            userName: c.userName,
            texto: c.texto,
            estrellas: c.estrellas,
            fecha: c.fecha,
            utilSi: tipo == 'si' ? c.utilSi + 1 : c.utilSi,
            utilNo: tipo == 'no' ? c.utilNo + 1 : c.utilNo,
            publico: c.publico,
          );
          notifyListeners();
        }
        return true;
      }
      _error = 'No se pudo marcar utilidad';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al marcar utilidad: $e';
      notifyListeners();
      return false;
    }
  }
}
