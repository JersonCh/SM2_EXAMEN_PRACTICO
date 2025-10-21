import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stands_viewmodel.dart';
import '../../models/evento.dart';
import '../../models/zona.dart';
import 'crear_stand_page.dart';

class StandsPage extends StatefulWidget {
  const StandsPage({super.key});

  @override
  State<StandsPage> createState() => _StandsPageState();
}

class _StandsPageState extends State<StandsPage> {
  @override
  void initState() {
    super.initState();
    // Inicializar carga de eventos después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StandsViewModel>().inicializarEventosSiEsNecesario();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StandsViewModel>(
      builder: (context, standsViewModel, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título principal con botón de recarga
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gestión de Stands',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1B1B),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          standsViewModel.cargarEventos();
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recargar eventos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mostrar errores si los hay
                  if (standsViewModel.error.isNotEmpty) ...[
                    _buildErrorCard(standsViewModel),
                    const SizedBox(height: 16),
                  ],

                  // Contenido scrolleable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selector de evento
                          _buildSelectorEvento(standsViewModel),
                          const SizedBox(height: 16),

                          // Selector de zona (solo si hay evento seleccionado)
                          if (standsViewModel.eventoSeleccionado != null) ...[
                            _buildSelectorZona(standsViewModel),
                            const SizedBox(height: 16),
                          ],

                          // Botón agregar stand (solo si hay evento y zona seleccionados)
                          if (standsViewModel.eventoSeleccionado != null &&
                              standsViewModel.zonaSeleccionada != null) ...[
                            _buildBotonAgregarStand(context),
                            const SizedBox(height: 16),
                          ],

                          // Lista de stands con altura mínima
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: _buildListaStands(standsViewModel),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectorEvento(StandsViewModel standsViewModel) {
    // Asegurar que se inicialicen los eventos si aún no se ha hecho
    if (standsViewModel.eventos.isEmpty &&
        !standsViewModel.isLoading &&
        standsViewModel.error.isEmpty) {
      standsViewModel.inicializarEventosSiEsNecesario();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final maxDropdownHeight =
        screenHeight * 0.25; // Máximo 25% de la altura de pantalla

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Evento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child:
                  standsViewModel.isLoading
                      ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Cargando eventos...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : DropdownButtonHideUnderline(
                        child: DropdownButton<Evento>(
                          value: standsViewModel.eventoSeleccionado,
                          isExpanded: true,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 16.0,
                            ),
                            child: Text(
                              standsViewModel.eventos.isEmpty
                                  ? (standsViewModel.error.isNotEmpty
                                      ? 'Error cargando eventos'
                                      : 'No hay eventos disponibles')
                                  : 'Seleccione un evento',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(Icons.arrow_drop_down),
                          ),
                          menuMaxHeight: maxDropdownHeight,
                          itemHeight:
                              50, // Altura fija más pequeña para cada item
                          selectedItemBuilder: (BuildContext context) {
                            return standsViewModel.eventos.map<Widget>((
                              Evento evento,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 14.0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    evento.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          items:
                              standsViewModel.eventos.map((evento) {
                                return DropdownMenuItem<Evento>(
                                  value: evento,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      evento.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              standsViewModel.eventos.isEmpty
                                  ? null
                                  : (evento) {
                                    standsViewModel.setEventoSeleccionado(
                                      evento,
                                    );
                                  },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorZona(StandsViewModel standsViewModel) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDropdownHeight =
        screenHeight * 0.25; // Máximo 25% de la altura de pantalla

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Zona',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child:
                  standsViewModel.isLoadingZonas
                      ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Cargando zonas...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : DropdownButtonHideUnderline(
                        child: DropdownButton<Zona>(
                          value: standsViewModel.zonaSeleccionada,
                          isExpanded: true,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 16.0,
                            ),
                            child: Text(
                              standsViewModel.zonasDisponibles.isEmpty
                                  ? 'No hay zonas disponibles para este evento'
                                  : 'Seleccione una zona',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(Icons.arrow_drop_down),
                          ),
                          menuMaxHeight: maxDropdownHeight,
                          itemHeight:
                              50, // Altura fija más pequeña para cada item
                          selectedItemBuilder: (BuildContext context) {
                            return standsViewModel.zonasDisponibles.map<Widget>(
                              (Zona zona) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 14.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      zona.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ).toList();
                          },
                          items:
                              standsViewModel.zonasDisponibles.map((zona) {
                                return DropdownMenuItem<Zona>(
                                  value: zona,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      zona.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              standsViewModel.zonasDisponibles.isEmpty
                                  ? null
                                  : (zona) {
                                    standsViewModel.setZonaSeleccionada(zona);
                                  },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonAgregarStand(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearStandPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar Nuevo Stand'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B1B1B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildListaStands(StandsViewModel standsViewModel) {
    if (standsViewModel.eventoSeleccionado == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Seleccione un evento para ver los stands',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final stands =
        standsViewModel.zonaSeleccionada != null
            ? standsViewModel.getStandsPorZona(
              standsViewModel.eventoSeleccionado!.id,
              standsViewModel.zonaSeleccionada!.numero,
            )
            : standsViewModel.getStandsPorEvento(
              standsViewModel.eventoSeleccionado!.id,
            );

    if (stands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              standsViewModel.zonaSeleccionada != null
                  ? 'No hay stands en esta zona'
                  : 'No hay stands registrados para este evento',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: stands.length,
      itemBuilder: (context, index) {
        final stand = stands[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF8B1B1B),
              child: Text(
                stand.nombreEmpresa[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              stand.nombreEmpresa,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zona: ${stand.zonaNombre}'),
                if (stand.productos.isNotEmpty)
                  Text(
                    'Productos: ${stand.productos.take(3).join(', ')}${stand.productos.length > 3 ? '...' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
              onSelected: (value) {
                if (value == 'eliminar') {
                  _confirmarEliminarStand(
                    context,
                    stand.id,
                    stand.nombreEmpresa,
                  );
                }
                // TODO: Implementar editar stand
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmarEliminarStand(
    BuildContext context,
    String standId,
    String nombreEmpresa,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Está seguro de que desea eliminar el stand "$nombreEmpresa"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<StandsViewModel>().eliminarStand(standId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Widget _buildErrorCard(StandsViewModel standsViewModel) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                standsViewModel.error,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => standsViewModel.limpiarError(),
              color: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }
}
