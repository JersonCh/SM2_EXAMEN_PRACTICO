import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evento.dart';
import '../../models/actividad.dart';
import '../../viewmodels/actividades_viewmodel.dart';
import 'crear_actividad_page.dart';

class GestionarActividadesPage extends StatefulWidget {
  final Evento evento;

  const GestionarActividadesPage({super.key, required this.evento});

  @override
  State<GestionarActividadesPage> createState() => _GestionarActividadesPageState();
}

class _GestionarActividadesPageState extends State<GestionarActividadesPage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<DateTime> _diasEvento = [];

  @override
  void initState() {
    super.initState();
    _configurarDiasEvento();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarActividades();
    });
  }

  void _configurarDiasEvento() {
    final viewModel = context.read<ActividadesViewModel>();
    _diasEvento = viewModel.generarDiasDelEvento(
      widget.evento.fechaInicio,
      widget.evento.fechaFin,
    );
    
    _tabController = TabController(
      length: _diasEvento.length,
      vsync: this,
    );
  }

  Future<void> _cargarActividades() async {
    final viewModel = context.read<ActividadesViewModel>();
    await viewModel.cargarActividadesPorEvento(widget.evento.id);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Actividades - ${widget.evento.nombre}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        bottom: _diasEvento.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: _diasEvento.length > 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: _diasEvento.map((dia) => Tab(
                  text: _formatearDiaTab(dia),
                )).toList(),
              )
            : null,
      ),
      body: Consumer<ActividadesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.state == ActividadesState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar actividades',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.errorMessage,
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _cargarActividades,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (_diasEvento.isEmpty) {
            return const Center(
              child: Text('No se pudieron cargar los días del evento'),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _diasEvento.map((dia) => RefreshIndicator(
              onRefresh: _cargarActividades,
              child: _buildActividadesDia(viewModel, dia),
            )).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearNuevaActividad,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Actividad'),
      ),
    );
  }

  Widget _buildActividadesDia(ActividadesViewModel viewModel, DateTime dia) {
    final actividades = viewModel.obtenerActividadesDeDia(dia);

    if (actividades.isEmpty) {
      return _buildDiaSinActividades(dia);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actividades.length,
      itemBuilder: (context, index) {
        final actividad = actividades[index];
        return _buildTarjetaActividad(actividad);
      },
    );
  }

  Widget _buildDiaSinActividades(DateTime dia) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin actividades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay actividades programadas para ${_formatearDiaCompleto(dia)}',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _crearNuevaActividad,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Actividad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaActividad(Actividad actividad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editarActividad(actividad),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con horario y acciones
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      actividad.horario,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton(
                    iconSize: 20,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 20),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red, size: 20),
                          title: Text('Eliminar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) => _manejarAccionActividad(value, actividad),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Título de la actividad
              Text(
                actividad.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Zona
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    actividad.zona,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _manejarAccionActividad(String accion, Actividad actividad) {
    switch (accion) {
      case 'editar':
        _editarActividad(actividad);
        break;
      case 'eliminar':
        _mostrarDialogoEliminar(actividad);
        break;
    }
  }

  void _crearNuevaActividad() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearActividadPage(
          evento: widget.evento,
        ),
      ),
    );

    if (resultado == true) {
      // Forzar recarga completa
      await _cargarActividades();
      // Asegurar que se actualice la UI
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _editarActividad(Actividad actividad) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearActividadPage(
          evento: widget.evento,
          actividad: actividad,
        ),
      ),
    );

    if (resultado == true) {
      // Forzar recarga completa
      await _cargarActividades();
      // Asegurar que se actualice la UI
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _mostrarDialogoEliminar(Actividad actividad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la actividad "${actividad.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Guardar referencia al contexto ANTES de pop
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              final viewModel = context.read<ActividadesViewModel>();
              final exito = await viewModel.eliminarActividad(actividad.id);
              
              // Usar la referencia guardada
              if (exito) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Actividad eliminada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar la actividad'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatearDiaTab(DateTime dia) {
    return '${dia.day}/${dia.month}';
  }

  String _formatearDiaCompleto(DateTime dia) {
    return '${dia.day}/${dia.month}/${dia.year}';
  }
}