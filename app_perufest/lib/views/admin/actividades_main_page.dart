import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evento.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import 'gestionar_actividades_page.dart';

class ActividadesMainPage extends StatefulWidget {
  const ActividadesMainPage({super.key});

  @override
  State<ActividadesMainPage> createState() => _ActividadesMainPageState();
}

class _ActividadesMainPageState extends State<ActividadesMainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventos();
    });
  }

  Future<void> _cargarEventos() async {
    final viewModel = context.read<EventosViewModel>();
    await viewModel.cargarEventos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Actividades'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<EventosViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.state == EventosState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar eventos',
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
                    onPressed: _cargarEventos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasEventos) {
            return _buildSinEventos();
          }

          return RefreshIndicator(
            onRefresh: _cargarEventos,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.eventos.length,
              itemBuilder: (context, index) {
                final evento = viewModel.eventos[index];
                return _buildTarjetaEvento(evento);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSinEventos() {
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
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los eventos creados aparecerán aquí para gestionar sus actividades',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaEvento(Evento evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navegarAActividades(evento),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono del evento
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getIconoCategoria(evento.categoria),
                  color: Colors.blue.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Información del evento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evento.lugar,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChipEstado(evento.estado),
                        const SizedBox(width: 8),
                        _buildChipFechas(evento),
                      ],
                    ),
                  ],
                ),
              ),
              // Flecha indicadora
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipEstado(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorEstado(estado),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChipFechas(Evento evento) {
    final duracion = evento.fechaFin.difference(evento.fechaInicio).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        duracion == 0 ? '1 día' : '${duracion + 1} días',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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

  void _navegarAActividades(Evento evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionarActividadesPage(evento: evento),
      ),
    );
  }
}