import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evento.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import 'editar_evento_page.dart';

class DetalleEventoPage extends StatefulWidget {
  final Evento evento;
  
  const DetalleEventoPage({super.key, required this.evento});

  @override
  State<DetalleEventoPage> createState() => _DetalleEventoPageState();
}

class _DetalleEventoPageState extends State<DetalleEventoPage> {
  late Evento eventoActual;

  @override
  void initState() {
    super.initState();
    eventoActual = widget.evento;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventosViewModel>(
      builder: (context, viewModel, child) {
        // Buscar el evento actualizado en la lista del ViewModel
        final eventoEnLista = viewModel.eventos.where((e) => e.id == widget.evento.id).isNotEmpty
            ? viewModel.eventos.firstWhere((e) => e.id == widget.evento.id)
            : eventoActual;
        
        // Actualizar el evento actual si encontramos uno más reciente
        if (eventoEnLista.fechaActualizacion.isAfter(eventoActual.fechaActualizacion)) {
          eventoActual = eventoEnLista;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del Evento'),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Editar'),
                    ),
                  ),
                  if (eventoActual.estado == 'activo') ...[
                    const PopupMenuItem(
                      value: 'cancelar',
                      child: ListTile(
                        leading: Icon(Icons.cancel, color: Colors.orange),
                        title: Text('Cancelar'),
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Eliminar'),
                    ),
                  ),
                ],
                onSelected: (value) => _manejarAccion(context, value),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del evento
                _buildImagenEvento(),
                // Información principal
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado y categoría
                      Row(
                        children: [
                          _buildChipEstado(),
                          const SizedBox(width: 8),
                          _buildChipCategoria(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Título
                      Text(
                        eventoActual.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Organizador
                      Row(
                        children: [
                          const Icon(Icons.business, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Organizado por ${eventoActual.organizador}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Fechas y horarios
                      _buildSeccionFechas(),
                      const SizedBox(height: 24),
                      // Ubicación
                      _buildSeccionUbicacion(),
                      const SizedBox(height: 24),
                      // Descripción
                      _buildSeccionDescripcion(),
                      const SizedBox(height: 24),
                      // Información adicional
                      _buildSeccionInformacionAdicional(),
                      const SizedBox(height: 24),
                      // Botones de acción
                      _buildBotonesAccion(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagenEvento() {
    if (eventoActual.imagenUrl.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconoCategoria(eventoActual.categoria),
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin imagen',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Image.network(
        eventoActual.imagenUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error al cargar imagen',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: Colors.grey.shade300,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildChipEstado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColorEstado(eventoActual.estado),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        eventoActual.estado.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChipCategoria() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconoCategoria(eventoActual.categoria),
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            eventoActual.categoria,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionFechas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Fechas y Horarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.play_arrow, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inicio:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatearFechaCompleta(eventoActual.fechaInicio)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.stop, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fin:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatearFechaCompleta(eventoActual.fechaFin)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Duración: ${_calcularDuracion()}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionUbicacion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Ubicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              eventoActual.lugar,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionDescripcion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Descripción',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              eventoActual.descripcion,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionInformacionAdicional() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Información Adicional',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Creado por:', eventoActual.creadoPor),
            _buildInfoRow('Fecha de creación:', _formatearFecha(eventoActual.fechaCreacion)),
            _buildInfoRow('Última actualización:', _formatearFecha(eventoActual.fechaActualizacion)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _editarEvento(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.edit),
              label: const Text('Editar'),
            ),
          ),
          const SizedBox(width: 8),
          if (eventoActual.estado == 'activo')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _cambiarEstado(context, 'cancelado'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.cancel_presentation),
                label: const Text('Cancelar Evento'),
              ),
            ),
        ],
      ),
    );
  }

  void _editarEvento(BuildContext context) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarEventoPage(evento: eventoActual),
      ),
    );
    
    // Si se devolvió el evento actualizado, actualizar el estado local
    if (resultado is Evento) {
      setState(() {
        eventoActual = resultado;
      });
    }
    // Si se devolvió true, recargar desde el ViewModel
    else if (resultado == true) {
      final viewModel = context.read<EventosViewModel>();
      await viewModel.cargarEventos();
      
      // Buscar el evento actualizado
      final eventoEncontrado = viewModel.eventos.where((e) => e.id == eventoActual.id);
      if (eventoEncontrado.isNotEmpty) {
        setState(() {
          eventoActual = eventoEncontrado.first;
        });
      }
    }
  }

  void _manejarAccion(BuildContext context, String accion) {
    switch (accion) {
      case 'editar':
        _editarEvento(context);
        break;
      case 'cancelar':
        _cambiarEstado(context, 'cancelado');
        break;
      case 'eliminar':
        _mostrarDialogoEliminar(context);
        break;
    }
  }

  void _cambiarEstado(BuildContext context, String nuevoEstado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar ${nuevoEstado == 'cancelado' ? 'cancelación' : 'cambio'}'),
        content: Text('¿Estás seguro de que quieres ${nuevoEstado == 'cancelado' ? 'cancelar' : 'cambiar el estado de'} este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final exito = await context.read<EventosViewModel>().actualizarEstado(eventoActual.id, nuevoEstado);
              if (exito && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Estado actualizado a $nuevoEstado')),
                );
                
                // Actualizar el evento local
                setState(() {
                  eventoActual = eventoActual.copyWith(
                    estado: nuevoEstado,
                    fechaActualizacion: DateTime.now(),
                  );
                });
              }
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${eventoActual.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final exito = await context.read<EventosViewModel>().eliminarEvento(eventoActual.id);
              if (exito && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evento eliminado correctamente')),
                );
                Navigator.pop(context); // Regresar a la lista
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
        return Colors.orange;
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

  String _formatearFechaCompleta(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    
    final dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    
    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final ano = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    
    return '$diaSemana $dia de $mes de $ano a las $hora:$minuto';
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _calcularDuracion() {
    final duracion = eventoActual.fechaFin.difference(eventoActual.fechaInicio);
    final dias = duracion.inDays;
    final horas = duracion.inHours % 24;
    final minutos = duracion.inMinutes % 60;
    
    if (dias > 0) {
      return '$dias día${dias > 1 ? 's' : ''}, $horas hora${horas != 1 ? 's' : ''}';
    } else if (horas > 0) {
      return '$horas hora${horas != 1 ? 's' : ''}, $minutos minuto${minutos != 1 ? 's' : ''}';
    } else {
      return '$minutos minuto${minutos != 1 ? 's' : ''}';
    }
  }
}