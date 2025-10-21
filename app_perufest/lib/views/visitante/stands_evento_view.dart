import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evento.dart';
import '../../models/stand.dart';
import '../../viewmodels/stands_viewmodel.dart';
import 'comentarios_view.dart';

class StandsEventoView extends StatefulWidget {
  final Evento evento;

  const StandsEventoView({super.key, required this.evento});

  @override
  State<StandsEventoView> createState() => _StandsEventoViewState();
}

class _StandsEventoViewState extends State<StandsEventoView> {
  String? _zonaSeleccionada = 'Todas';
  List<Stand> _standsFiltrados = [];

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarStands();
    });
  }

  Future<void> _cargarStands() async {
    if (mounted) {
      print('DEBUG: Evento ID para cargar stands: ${widget.evento.id}');
      print('DEBUG: Evento nombre: ${widget.evento.nombre}');
      final standsViewModel = context.read<StandsViewModel>();
      await standsViewModel.cargarStandsPorEvento(widget.evento.id);
      _aplicarFiltro();
    }
  }

  void _aplicarFiltro() {
    if (mounted) {
      final standsViewModel = context.read<StandsViewModel>();
      setState(() {
        _standsFiltrados = standsViewModel.filtrarStandsPorZona(
          _zonaSeleccionada,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stands - ${widget.evento.nombre}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8B1B1B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B1B1B), Color(0xFFA52A2A)],
            ),
          ),
        ),
      ),
      body: Consumer<StandsViewModel>(
        builder: (context, standsViewModel, child) {
          if (standsViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1B1B)),
              ),
            );
          }

          if (standsViewModel.error.isNotEmpty) {
            return _buildErrorState(standsViewModel.error);
          }

          final zonasDisponibles = standsViewModel.getZonasUnicas();

          if (standsViewModel.stands.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildFiltroZonas(zonasDisponibles),
              Expanded(
                child:
                    _standsFiltrados.isEmpty
                        ? _buildNoResultsState()
                        : _buildStandsList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltroZonas(List<String> zonasDisponibles) {
    final todasLasZonas = ['Todas', ...zonasDisponibles];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: const Color(0xFF8B1B1B)),
              const SizedBox(width: 8),
              Text(
                'Filtrar por zona:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B1B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: todasLasZonas.length,
              itemBuilder: (context, index) {
                final zona = todasLasZonas[index];
                final isSelected = _zonaSeleccionada == zona;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      zona,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF8B1B1B),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _zonaSeleccionada = zona;
                      });
                      _aplicarFiltro();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF8B1B1B),
                    side: BorderSide(
                      color:
                          isSelected
                              ? const Color(0xFF8B1B1B)
                              : Colors.grey.shade300,
                    ),
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 3 : 1,
                    pressElevation: 5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandsList() {
    return RefreshIndicator(
      color: const Color(0xFF8B1B1B),
      onRefresh: _cargarStands,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _standsFiltrados.length,
        itemBuilder: (context, index) {
          final stand = _standsFiltrados[index];
          return _buildStandCard(stand);
        },
      ),
    );
  }

  Widget _buildStandCard(Stand stand) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con imagen y nombre
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B1B1B),
                  const Color(0xFF8B1B1B).withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Imagen de fondo si existe
                if (stand.imagenUrl.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        stand.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF8B1B1B),
                                  const Color(0xFF8B1B1B).withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.store,
                                size: 40,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF8B1B1B),
                          const Color(0xFF8B1B1B).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.store,
                        size: 40,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),

                // Overlay con gradiente para mejorar legibilidad
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // Contenido del header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Zona badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stand.zonaNombre.isEmpty
                              ? 'Sin zona'
                              : stand.zonaNombre,
                          style: const TextStyle(
                            color: Color(0xFF8B1B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Nombre de la empresa
                      Text(
                        stand.nombreEmpresa,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido del stand
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripción
                if (stand.descripcion.isNotEmpty) ...[
                  Text(
                    stand.descripcion,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Productos
                if (stand.productos.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 16,
                        color: const Color(0xFF8B1B1B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Productos: ${stand.productos.join(', ')}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Contacto
                Row(
                  children: [
                    if (stand.contacto.isNotEmpty) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: const Color(0xFF8B1B1B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stand.contacto,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (stand.telefono.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          // Aquí podrías abrir el dialer o WhatsApp
                          _mostrarOpcionesContacto(stand.telefono);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1B1B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Llamar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Botón para valorar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                    // Import dinámico para evitar ciclos
                                    // Usaremos la vista creada 'ComentariosView'
                                    // que debe existir en views/visitante/comentarios_view.dart
                                    // Pasar standId y nombre
                                    ComentariosView(
                                      standId: stand.id,
                                      standNombre: stand.nombreEmpresa,
                                    ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Valorar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1B1B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar stands',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarStands,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1B1B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_mall_directory_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay stands disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los stands aparecerán aquí cuando estén registrados para este evento',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarStands,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1B1B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay stands en esta zona',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta seleccionar otra zona o "Todas"',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesContacto(String telefono) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Contactar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B1B1B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  telefono,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Aquí implementarías la lógica para llamar
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Llamar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1B1B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Aquí implementarías la lógica para WhatsApp
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
