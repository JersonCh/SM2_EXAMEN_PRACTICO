import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/evento.dart';
import '../../models/zona_mapa.dart';
import '../../services/eventos_service.dart';
import '../../services/zonas_service.dart';

class MapaAdminView extends StatefulWidget {
  const MapaAdminView({super.key});

  @override
  State<MapaAdminView> createState() => _MapaAdminViewState();
}

class _MapaAdminViewState extends State<MapaAdminView> {
  final MapController _mapController = MapController();
  final TextEditingController _nombreZonaController = TextEditingController();

  void _centrarEnZona(LatLng ubicacion) {
    _mapController.move(ubicacion, 18.0);
  }
  
  List<Evento> _eventos = [];
  List<ZonaMapa> _zonas = [];
  Evento? _eventoSeleccionado;
  LatLng? _ubicacionSeleccionada;
  bool _cargando = true;
  bool _guardando = false;
  
  // Coordenadas del Parque Perú-Tacna
  static const LatLng _parquePeruTacna = LatLng(-17.9949, -70.2120);

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  @override
  void dispose() {
    _nombreZonaController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    try {
      final eventos = await EventosService.obtenerEventos();
      setState(() {
        _eventos = eventos.where((e) => e.estaActivo).toList();
        _eventoSeleccionado = _eventos.isNotEmpty ? _eventos.first : null;
        _cargando = false;
      });
      if (_eventoSeleccionado != null) {
        await _cargarZonasDeEvento(_eventoSeleccionado!.id);
      }
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los eventos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarZonasDeEvento(String eventoId) async {
    try {
      final zonas = await ZonasService.obtenerZonasPorEvento(eventoId);
      setState(() {
        _zonas = zonas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las zonas del evento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarZona() async {
    if (_eventoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un evento primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una ubicación en el mapa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nombre = _nombreZonaController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre para la zona'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final nuevaZona = ZonaMapa(
        id: '',
        nombre: nombre,
        eventoId: _eventoSeleccionado!.id,
        ubicacion: _ubicacionSeleccionada!,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      final id = await ZonasService.crearZona(nuevaZona);
      
      // Actualizar la lista de zonas localmente primero
      setState(() {
        _zonas.add(nuevaZona.copyWith(id: id));
      });

      // Limpiar el formulario
      _nombreZonaController.clear();
      setState(() {
        _ubicacionSeleccionada = null;
      });

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Zona guardada correctamente'),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _centrarEnZona(nuevaZona.ubicacion);
                  },
                  child: const Text(
                    'VER',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la zona'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _guardando = false;
      });
    }
  }

  Future<void> _eliminarZona(ZonaMapa zona) async {
    try {
      await ZonasService.eliminarZona(zona.id);
      await _cargarZonasDeEvento(_eventoSeleccionado!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zona eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la zona'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B1B1B),
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverFillRemaining(
                  child: _buildMapContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF8B1B1B),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Administrar Zonas del Evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Color.fromARGB(127, 0, 0, 0),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF8B1B1B).withOpacity(0.9),
                const Color(0xFF8B1B1B),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.edit_location_alt,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Column(
        children: [
          // Panel de control
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de eventos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: const Color(0xFF8B1B1B)),
                  ),
                  child: DropdownButton<Evento>(
                    value: _eventoSeleccionado,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Selecciona un evento'),
                    items: _eventos.map((evento) {
                      return DropdownMenuItem<Evento>(
                        value: evento,
                        child: Text(
                          evento.nombre,
                          style: const TextStyle(
                            color: Color(0xFF8B1B1B),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (Evento? evento) {
                      setState(() {
                        _eventoSeleccionado = evento;
                        _ubicacionSeleccionada = null;
                      });
                      if (evento != null) {
                        _cargarZonasDeEvento(evento.id);
                      } else {
                        setState(() {
                          _zonas = [];
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo para nombre de zona
                TextField(
                  controller: _nombreZonaController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la zona',
                    hintText: 'Ej: Zona de comidas, Escenario principal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B1B1B),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B1B1B),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Instrucciones
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Haz clic en el mapa para seleccionar la ubicación de la zona',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_ubicacionSeleccionada != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarZona,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1B1B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _guardando
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_guardando ? 'Guardando...' : 'Guardar Zona'),
                  ),
                ],
              ],
            ),
          ),
          
          // Mapa
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _parquePeruTacna,
                    initialZoom: 16.8,
                    minZoom: 16.0,
                    maxZoom: 19.0,
                    onTap: (tapPosition, point) {
                      // Solo permitir colocar puntos si hay un evento seleccionado
                      if (_eventoSeleccionado != null) {
                        setState(() {
                          _ubicacionSeleccionada = point;
                        });
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        final center = event.camera.center;
                        if ((center.latitude - _parquePeruTacna.latitude).abs() > 0.002 ||
                            (center.longitude - _parquePeruTacna.longitude).abs() > 0.002) {
                          _mapController.move(_parquePeruTacna, event.camera.zoom);
                        }
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app_perufest',
                      maxZoom: 19,
                    ),

                    // Marcador de ubicación seleccionada
                    if (_ubicacionSeleccionada != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _ubicacionSeleccionada!,
                            width: 50,
                            height: 50,
                            child: TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 500),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: 0.6 + (value * 0.4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add_location,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    // Marcadores de zonas existentes
                    MarkerLayer(
                      markers: _zonas.map((zona) {
                        return Marker(
                          point: zona.ubicacion,
                          width: 120,
                          height: 70,
                          child: Column(
                            children: [
                              // Nombre de la zona
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  zona.nombre,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B1B1B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Marcador
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(zona.nombre),
                                      content: const Text('¿Deseas eliminar esta zona?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _eliminarZona(zona);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B1B1B).withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    // Botones de zoom
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: "zoomIn",
                            onPressed: () {
                              final currentZoom = _mapController.camera.zoom;
                              _mapController.move(
                                _mapController.camera.center,
                                currentZoom + 0.5,
                              );
                            },
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.add, color: Color(0xFF8B1B1B)),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: "zoomOut",
                            onPressed: () {
                              final currentZoom = _mapController.camera.zoom;
                              _mapController.move(
                                _mapController.camera.center,
                                currentZoom - 0.5,
                              );
                            },
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.remove, color: Color(0xFF8B1B1B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}