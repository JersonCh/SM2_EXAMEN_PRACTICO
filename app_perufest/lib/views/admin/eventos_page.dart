import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import '../../models/evento.dart';
import 'crear_evento_page.dart';
import 'detalle_evento_page.dart';
import 'editar_evento_page.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  final TextEditingController _busquedaController = TextEditingController();
  String? _categoriaSeleccionada;

  final List<String> _categorias = [
    'Ferias y Exposiciones',
    'Festivales Culturales',
    'Conciertos'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventosViewModel>().cargarEventos();
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar eventos...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _busquedaController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _busquedaController.clear();
                              context.read<EventosViewModel>().buscarEventos('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    context.read<EventosViewModel>().buscarEventos(value);
                  },
                ),
                const SizedBox(height: 12),
                // Filtro por categoría
                DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ..._categorias.map((categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoriaSeleccionada = value;
                    });
                    context.read<EventosViewModel>().filtrarPorCategoria(value);
                  },
                ),
              ],
            ),
          ),
          // Lista de eventos
          Expanded(
            child: Consumer<EventosViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.state == EventosState.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.errorMessage,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => viewModel.cargarEventos(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (!viewModel.hasEventos) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay eventos disponibles',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.cargarEventos(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.eventos.length,
                    itemBuilder: (context, index) {
                      final evento = viewModel.eventos[index];
                      return _buildEventoCard(context, evento);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearEventoPage()),
          ).then((_) {
            // Recargar eventos al regresar
            context.read<EventosViewModel>().cargarEventos();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventoCard(BuildContext context, Evento evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorEstado(evento.estado),
          child: Icon(
            _getIconoCategoria(evento.categoria),
            color: Colors.white,
          ),
        ),
        title: Text(
          evento.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${evento.lugar} • ${evento.categoria}'),
            Text(
              '${_formatearFecha(evento.fechaInicio)} - ${_formatearFecha(evento.fechaFin)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getColorEstado(evento.estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                evento.estado.toUpperCase(),
                style: TextStyle(
                  color: _getColorEstado(evento.estado),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'ver',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Ver detalles'),
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar'),
              ),
            ),
          ],
          onSelected: (value) => _manejarAccion(context, value, evento),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleEventoPage(evento: evento),
            ),
          );
        },
      ),
    );
  }

  void _manejarAccion(BuildContext context, String accion, Evento evento) {
    switch (accion) {
      case 'ver':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleEventoPage(evento: evento),
          ),
        );
        break;
      case 'editar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarEventoPage(evento: evento),
          ),
        ).then((_) {
          context.read<EventosViewModel>().cargarEventos();
        });
        break;
      case 'eliminar':
        _mostrarDialogoEliminar(context, evento);
        break;
    }
  }

  void _mostrarDialogoEliminar(BuildContext context, Evento evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${evento.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final exito = await context.read<EventosViewModel>().eliminarEvento(evento.id);
              if (exito && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evento eliminado correctamente')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'activo':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'finalizado':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconoCategoria(String categoria) {
    switch (categoria) {
      case 'Ferias y Exposiciones':
        return Icons.store;
      case 'Festivales Culturales':
        return Icons.festival;
      case 'Conciertos':
        return Icons.music_note;
      default:
        return Icons.event;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}