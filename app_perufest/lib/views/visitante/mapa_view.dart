import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evento.dart';
import '../../models/zona_mapa.dart';
import '../../services/eventos_service.dart';
import '../../services/zonas_service.dart';


class MapaView extends StatefulWidget {
  const MapaView({super.key});

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> {
  final MapController _mapController = MapController();
  List<Evento> _eventos = [];
  List<ZonaMapa> _zonas = [];
  Evento? _eventoSeleccionado;
  bool _cargando = true;
  
  // Coordenadas del Parque Perú-Tacna (actualizadas según OpenStreetMap)
  static const LatLng _parquePeruTacna = LatLng(-17.9949, -70.2120);
  
  // Polígono que define el área triangular del parque (basado en OSM)
  final List<LatLng> _poligonoParque = [
    LatLng(-17.9952, -70.2125), // Esquina Oeste
    LatLng(-17.9945, -70.2115), // Esquina Norte
    LatLng(-17.9955, -70.2112), // Esquina Este
    LatLng(-17.9952, -70.2125), // Cierra el polígono (vuelve al inicio)
  ];

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    try {
      final eventos = await EventosService.obtenerEventos();
      if (mounted) {
        setState(() {
          _eventos = eventos.where((e) => e.estaActivo).toList();
          _eventoSeleccionado = _eventos.isNotEmpty ? _eventos.first : null;
          _cargando = false;
        });
      }
      if (_eventoSeleccionado != null) {
        await _cargarZonasDeEvento(_eventoSeleccionado!.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
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
      debugPrint('Cargando zonas para evento: $eventoId');
      final zonas = await ZonasService.obtenerZonasPorEvento(eventoId);
      debugPrint('Zonas cargadas: ${zonas.length}');
      for (var zona in zonas) {
        debugPrint('Zona: ${zona.nombre} en (${zona.ubicacion.latitude}, ${zona.ubicacion.longitude})');
      }
      if (mounted) {
        setState(() {
          _zonas = zonas;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar zonas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar las zonas del evento: $e'),
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
          'Ubicación del Evento',
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
                  Icons.location_on,
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
          // Información del lugar
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
                      if (mounted) {
                        setState(() {
                          _eventoSeleccionado = evento;
                        });
                      }
                      if (evento != null) {
                        _cargarZonasDeEvento(evento.id);
                      } else {
                        if (mounted) {
                          setState(() {
                            _zonas = [];
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Mapa OpenStreetMap
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
                    initialZoom: 16.8, // Zoom reducido para ver todo el área del parque
                    minZoom: 16.0, // Permite ver más contexto del entorno
                    maxZoom: 19.0, // Permite ver detalles para los puntos futuros
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        final center = event.camera.center;
                        // Mantener el mapa cerca del área triangular del parque
                        if ((center.latitude - _parquePeruTacna.latitude).abs() > 0.002 ||
                            (center.longitude - _parquePeruTacna.longitude).abs() > 0.002) {
                          _centrarMapa();
                        }
                      }
                    },
                    keepAlive: true,
                  ),
                  children: [
                    // Capa de tiles de OpenStreetMap
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app_perufest',
                      maxZoom: 19,
                    ),

                    // Marcadores de las zonas
                    MarkerLayer(
                      markers: _zonas.map((zona) => Marker(
                        point: zona.ubicacion,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(zona.nombre),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B1B1B).withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )).toList(),
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

                    // Atribución de OpenStreetMap
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => _launchUrl('https://openstreetmap.org/copyright'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botones 
          
        ],
      ),
    );
  }

  void _centrarMapa() {
    _mapController.move(_parquePeruTacna, 16.0);
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo abrir: $url'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir el enlace'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}