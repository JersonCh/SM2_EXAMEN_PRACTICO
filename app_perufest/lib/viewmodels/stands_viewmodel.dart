import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stand.dart';
import '../models/evento.dart';
import '../models/zona.dart';

class StandsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Stand> _stands = [];
  List<Evento> _eventos = [];
  List<Zona> _zonasDisponibles = [];
  bool _isLoading = false;
  bool _isLoadingZonas = false;
  String _error = '';

  // Getters
  List<Stand> get stands => _stands;
  List<Evento> get eventos => _eventos;
  List<Zona> get zonasDisponibles => _zonasDisponibles;
  bool get isLoading => _isLoading;
  bool get isLoadingZonas => _isLoadingZonas;
  String get error => _error;

  // Estado del formulario
  Evento? _eventoSeleccionado;
  Zona? _zonaSeleccionada;

  Evento? get eventoSeleccionado => _eventoSeleccionado;
  Zona? get zonaSeleccionada => _zonaSeleccionada;

  // Controladores para el formulario
  final TextEditingController nombreEmpresaController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController contactoController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController imagenUrlController = TextEditingController();
  final TextEditingController productosController = TextEditingController();

  StandsViewModel();

  // Variable para controlar si ya se intentó cargar los eventos
  bool _eventosIniciados = false;
  
  // Método para inicializar eventos si aún no se ha hecho
  void inicializarEventosSiEsNecesario() {
    if (!_eventosIniciados && !_isLoading) {
      _eventosIniciados = true;
      // Usar addPostFrameCallback para evitar setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cargarEventos();
      });
    }
  }

  void setEventoSeleccionado(Evento? evento) {
    _eventoSeleccionado = evento;
    _zonaSeleccionada = null; // Reset zona cuando cambia evento
    _zonasDisponibles.clear(); // Limpiar zonas anteriores
    notifyListeners();
    
    // Cargar zonas automáticamente al seleccionar evento
    if (evento != null) {
      cargarZonasPorEvento(evento.id);
    }
  }

  void setZonaSeleccionada(Zona? zona) {
    _zonaSeleccionada = zona;
    notifyListeners();
  }

  // Obtener stands por evento
  List<Stand> getStandsPorEvento(String eventoId) {
    return _stands.where((stand) => stand.eventoId == eventoId).toList();
  }

  // Obtener stands por zona
  List<Stand> getStandsPorZona(String eventoId, int zonaNumero) {
    return _stands
        .where(
          (stand) =>
              stand.eventoId == eventoId && stand.zonaNumero == zonaNumero,
        )
        .toList();
  }

  // Agregar nuevo stand
  Future<void> agregarStand() async {
    if (_eventoSeleccionado == null || _zonaSeleccionada == null) {
      _error = 'Debe seleccionar un evento y una zona';
      notifyListeners();
      return;
    }

    if (nombreEmpresaController.text.trim().isEmpty) {
      _error = 'El nombre de la empresa es requerido';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Procesar productos
      List<String> productos =
          productosController.text
              .split(',')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();

      final nuevoStand = Stand(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombreEmpresa: nombreEmpresaController.text.trim(),
        descripcion: descripcionController.text.trim(),
        imagenUrl: imagenUrlController.text.trim(),
        eventoId: _eventoSeleccionado!.id,
        zonaNumero: _zonaSeleccionada!.numero,
        zonaNombre: _zonaSeleccionada!.nombre,
        productos: productos,
        contacto: contactoController.text.trim(),
        telefono: telefonoController.text.trim(),
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      // Guardar en Firestore en la colección 'stands'
      final docRef = _firestore.collection('stands').doc(nuevoStand.id);
      final data = Map<String, dynamic>.from(nuevoStand.toJson());
      // Convertir fechas a Timestamp para Firestore
      data['fecha_creacion'] = Timestamp.fromDate(nuevoStand.fechaCreacion);
      data['fecha_actualizacion'] = Timestamp.fromDate(
        nuevoStand.fechaActualizacion,
      );

      await docRef.set(data);

      // Añadir localmente
      _stands.add(nuevoStand);
      _limpiarFormulario();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al guardar el stand: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar stand
  Future<void> eliminarStand(String standId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Intentar eliminar en Firestore (si existe)
      try {
        await _firestore.collection('stands').doc(standId).delete();
      } catch (_) {
        // Ignorar si no existe o falla; igual removeremos localmente
      }

      _stands.removeWhere((stand) => stand.id == standId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar el stand: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar formulario
  void _limpiarFormulario() {
    nombreEmpresaController.clear();
    descripcionController.clear();
    contactoController.clear();
    telefonoController.clear();
    imagenUrlController.clear();
    productosController.clear();
    _eventoSeleccionado = null;
    _zonaSeleccionada = null;
  }

  void limpiarFormulario() {
    _limpiarFormulario();
    notifyListeners();
  }

  void limpiarError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar todos los datos
  Future<void> refrescarDatos() async {
    await Future.wait([
      cargarEventos(),
      cargarStands(),
    ]);
  }

  // Verificar si hay datos cargados
  bool get tieneDatos => _eventos.isNotEmpty;

  // Método auxiliar para parsear fechas que pueden estar como String o Timestamp
  DateTime? _parseDate(dynamic dateField) {
    if (dateField == null) return null;
    
    try {
      // Si es un Timestamp de Firestore
      if (dateField is Timestamp) {
        return dateField.toDate();
      }
      
      // Si es un String
      if (dateField is String) {
        return DateTime.parse(dateField);
      }
      
      // Si es un DateTime ya
      if (dateField is DateTime) {
        return dateField;
      }
      
      return null;
    } catch (e) {
      print('DEBUG: Error al parsear fecha $dateField: $e');
      return null;
    }
  }

  // Cargar eventos activos desde Firestore
  Future<void> cargarEventos() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      print('DEBUG: Iniciando carga de eventos...');
      
      final querySnapshot = await _firestore
          .collection('eventos')
          .where('estado', isEqualTo: 'activo')
          .get();

      print('DEBUG: Eventos encontrados: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        _eventos = [];
        _error = 'No hay eventos activos disponibles';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _eventos = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return Evento(
            id: doc.id,
            nombre: data['nombre'] ?? '',
            descripcion: data['descripcion'] ?? '',
            organizador: data['organizador'] ?? '',
            categoria: data['categoria'] ?? '',
            fechaInicio: _parseDate(data['fechaInicio']) ?? DateTime.now(),
            fechaFin: _parseDate(data['fechaFin']) ?? DateTime.now().add(const Duration(days: 1)),
            lugar: data['lugar'] ?? '',
            imagenUrl: data['imagenUrl'] ?? '',
            creadoPor: data['creadoPor'] ?? '',
            estado: data['estado'] ?? 'activo',
            fechaCreacion: _parseDate(data['fechaCreacion']) ?? DateTime.now(),
            fechaActualizacion: _parseDate(data['fechaActualizacion']) ?? DateTime.now(),
          );
        } catch (e) {
          throw Exception('Error al procesar evento ${doc.id}: $e');
        }
      }).toList();

      print('DEBUG: Eventos cargados exitosamente: ${_eventos.length}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error al cargar eventos: $e');
      // Mensaje más descriptivo dependiendo del tipo de error
      if (e.toString().contains('type cast')) {
        _error = 'Error de formato en los datos del evento. Verifique la estructura en Firestore.';
      } else if (e.toString().contains('permission')) {
        _error = 'Error de permisos. No se puede acceder a la colección de eventos.';
      } else if (e.toString().contains('network')) {
        _error = 'Error de conexión. Verifique su conexión a internet.';
      } else {
        _error = 'Error al cargar eventos: ${e.toString()}';
      }
      _eventos = []; // Limpiar la lista en caso de error
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar zonas por evento desde Firestore
  Future<void> cargarZonasPorEvento(String eventoId) async {
    if (eventoId.isEmpty) {
      _zonasDisponibles = [];
      notifyListeners();
      return;
    }

    try {
      _isLoadingZonas = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('zonas')
          .where('eventoId', isEqualTo: eventoId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _zonasDisponibles = [];
        _isLoadingZonas = false;
        notifyListeners();
        return;
      }

      _zonasDisponibles = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data();
          final nombre = data['nombre'] ?? '';
          
          // Buscar la zona correspondiente en el catálogo estático
          final zonaEstatica = ZonasParque.obtenerPorNombre(nombre);
          if (zonaEstatica != null) {
            return zonaEstatica;
          }
          
          // Si no se encuentra en el catálogo, crear una zona temporal
          return Zona(
            numero: data['numero'] ?? 0,
            nombre: nombre,
            descripcion: data['descripcion'] ?? 'Zona del evento',
          );
        } catch (e) {
          throw Exception('Error al procesar zona del documento ${doc.id}: $e');
        }
      }).toList();

      _isLoadingZonas = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar zonas para evento $eventoId: ${e.toString()}';
      _zonasDisponibles = []; // Limpiar zonas en caso de error
      _isLoadingZonas = false;
      notifyListeners();
    }
  }

  // Cargar stands desde Firestore
  Future<void> cargarStands() async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore.collection('stands').get();

      _stands = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Stand(
          id: doc.id,
          nombreEmpresa: data['nombreEmpresa'] ?? '',
          descripcion: data['descripcion'] ?? '',
          imagenUrl: data['imagenUrl'] ?? '',
          eventoId: data['eventoId'] ?? '',
          zonaNumero: data['zonaNumero'] ?? 0,
          zonaNombre: data['zonaNombre'] ?? '',
          productos: List<String>.from(data['productos'] ?? []),
          contacto: data['contacto'] ?? '',
          telefono: data['telefono'] ?? '',
          fechaCreacion: _parseDate(data['fecha_creacion']) ?? DateTime.now(),
          fechaActualizacion: _parseDate(data['fecha_actualizacion']) ?? DateTime.now(),
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar stands: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar stands específicos por evento
  Future<void> cargarStandsPorEvento(String eventoId) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      print('DEBUG: Buscando stands para evento ID: $eventoId');

      // Primero, obtener todos los stands para debug
      final allStandsQuery = await _firestore.collection('stands').get();
      print('DEBUG: Total stands en base de datos: ${allStandsQuery.docs.length}');
      
      for (var doc in allStandsQuery.docs) {
        final data = doc.data();
        print('DEBUG: Stand en DB - ID: ${doc.id}, evento_id: ${data['evento_id']}, nombre: ${data['nombre_empresa']}');
      }

      // Ahora buscar específicamente para este evento
      final querySnapshot = await _firestore
          .collection('stands')
          .where('evento_id', isEqualTo: eventoId)
          .where('estado', isEqualTo: 'activo')
          .get();

      print('DEBUG: Stands encontrados para evento $eventoId: ${querySnapshot.docs.length}');
      
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          print('DEBUG: Stand encontrado: ${doc.data()}');
        }
      }

      _stands = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Stand(
          id: doc.id,
          nombreEmpresa: data['nombre_empresa'] ?? data['nombreEmpresa'] ?? '',
          descripcion: data['descripcion'] ?? '',
          imagenUrl: data['imagen_url'] ?? data['imagenUrl'] ?? '',
          eventoId: data['evento_id'] ?? data['eventoId'] ?? '',
          zonaNumero: data['zona_numero'] ?? data['zonaNumero'] ?? 0,
          zonaNombre: data['zona_nombre'] ?? data['zonaNombre'] ?? '',
          productos: List<String>.from(data['productos'] ?? []),
          contacto: data['contacto'] ?? '',
          telefono: data['telefono'] ?? '',
          fechaCreacion: _parseDate(data['fecha_creacion']) ?? DateTime.now(),
          fechaActualizacion: _parseDate(data['fecha_actualizacion']) ?? DateTime.now(),
        );
      }).toList();

      print('DEBUG: Stands procesados: ${_stands.length}');

      _error = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error al cargar stands: $e');
      _error = 'Error al cargar stands del evento: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener zonas únicas de los stands cargados
  List<String> getZonasUnicas() {
    final zonasSet = <String>{};
    for (final stand in _stands) {
      if (stand.zonaNombre.isNotEmpty) {
        zonasSet.add(stand.zonaNombre);
      }
    }
    return zonasSet.toList()..sort();
  }

  // Filtrar stands por zona
  List<Stand> filtrarStandsPorZona(String? zonaNombre) {
    if (zonaNombre == null || zonaNombre.isEmpty || zonaNombre == 'Todas') {
      return _stands;
    }
    return _stands.where((stand) => stand.zonaNombre == zonaNombre).toList();
  }
}
