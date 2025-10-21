import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evento.dart';
import '../../models/actividad.dart';
import '../../viewmodels/actividades_viewmodel.dart';
import '../../viewmodels/agenda_viewmodel.dart';
import '../../services/notificaciones_service.dart';
class ActividadesEventoView extends StatefulWidget {
  final Evento evento;
  final String userId; // Agregar userId como parámetro

  const ActividadesEventoView({
    super.key, 
    required this.evento,
    required this.userId,
  });
  @override
  State<ActividadesEventoView> createState() => _ActividadesEventoViewState();
}
class _ActividadesEventoViewState extends State<ActividadesEventoView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<DateTime> _diasEvento = [];
  final List<Color> _colorPalette = [
    const Color(0xFF8B1B1B), // Guinda principal
    const Color(0xFFA52A2A), // Rojo-marrón
    const Color(0xFF8B0000), // Rojo oscuro
    const Color(0xFF800020), // Burgundy
    const Color(0xFF722F37), // Marrón-rojo
    const Color(0xFF9B1B1B), // Guinda claro
    const Color(0xFF7B1B1B), // Guinda oscuro
    const Color(0xFF8B2635), // Guinda-rosado
    const Color(0xFF8B3A3A), // Rojo tierra
    const Color(0xFF8B4B4B), // Rojo suave
  ];
  @override
  void initState() {
    super.initState();
    _configurarDiasEvento();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configurarAgenda();
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
  void _configurarAgenda() {
    final agendaViewModel = context.read<AgendaViewModel>();
    agendaViewModel.configurarUsuario(widget.userId);
  }
  Future<void> _cargarActividades() async {
    final viewModel = context.read<ActividadesViewModel>();
    await viewModel.cargarActividadesPorEvento(widget.evento.id);

    // Verificar estado de agenda para todas las actividades
    final agendaViewModel = context.read<AgendaViewModel>();
    final actividadesIds = viewModel.actividades.map((a) => a.id).toList();
    await agendaViewModel.verificarEstadoActividades(actividadesIds);
  }
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ActividadesViewModel>(
        builder: (context, viewModel, child) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (viewModel.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando actividades...'),
                      ],
                    ),
                  ),
                )
              else if (viewModel.state == ActividadesState.error)
                SliverFillRemaining(
                  child: _buildErrorState(viewModel),
                )
              else
                _buildActividadesContent(viewModel),
            ],
          );
        },
      ),
    );
  }
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF8B1B1B),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B1B1B).withOpacity(0.9),
                const Color(0xFF8B1B1B),
                const Color(0xFF8B0000),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.celebration,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.evento.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(2.0, 2.0),
                              blurRadius: 4.0,
                              color: Color.fromARGB(127, 0, 0, 0),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white.withOpacity(0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatearFecha(widget.evento.fechaInicio)} - ${_formatearFecha(widget.evento.fechaFin)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white.withOpacity(0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.evento.lugar,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: _diasEvento.isNotEmpty
          ? TabBar(
              controller: _tabController,
              isScrollable: _diasEvento.length > 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: _diasEvento.map((dia) => Tab(
                text: _formatearDiaTab(dia),
              )).toList(),
            )
          : null,
    );
  }
  Widget _buildActividadesContent(ActividadesViewModel viewModel) {
    if (_diasEvento.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyDaysState(),
      );
    }
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: _diasEvento.map((dia) => _buildActividadesDia(viewModel, dia)).toList(),
      ),
    );
  }
  Widget _buildActividadesDia(ActividadesViewModel viewModel, DateTime dia) {
    final actividades = viewModel.obtenerActividadesDeDia(dia);
    if (actividades.isEmpty) {
      return _buildDiaSinActividades(dia);
    }
    actividades.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return RefreshIndicator(
      onRefresh: _cargarActividades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: actividades.length,
        itemBuilder: (context, index) {
          final actividad = actividades[index];
          final color = _colorPalette[index % _colorPalette.length];
          return _buildTarjetaActividad(actividad, color);
        },
      ),
    );
  }
  Widget _buildTarjetaActividad(Actividad actividad, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con horario
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            actividad.horario,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        actividad.zona,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nombre de la actividad
                Text(
                  actividad.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Información adicional
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Duración: ${actividad.duracion}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                if (actividad.zona.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          actividad.zona,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // BOTÓN AGENDAR - NUEVA FUNCIONALIDAD
                _buildBotonAgendar(actividad),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Replace the _buildBotonAgendar method
  Widget _buildBotonAgendar(Actividad actividad) {
    return Consumer<AgendaViewModel>(
      builder: (context, agendaViewModel, child) {
        final estaEnAgenda = agendaViewModel.estaEnAgenda(actividad.id);
        final estaCargando = agendaViewModel.estaCargando(actividad.id);
        
        // Obtener hora actual
        final ahora = DateTime.now();
        
        // La actividad YA INICIÓ si la hora actual es POSTERIOR a la hora de inicio
        // Agregamos un pequeño buffer de 1 minuto para evitar problemas de sincronización
        final yaInicio = ahora.isAfter(actividad.fechaInicio.add(const Duration(minutes: 1)));
        
        print('¿Ya inició?: $yaInicio');
        print('==============================');
        
        if (yaInicio && !estaEnAgenda) {
          return SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Actividad ya iniciada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: estaCargando ? null : () => _manejarBotonAgendar(actividad),
            style: ElevatedButton.styleFrom(
              backgroundColor: estaEnAgenda ? Colors.green : const Color(0xFF8B1B1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: estaCargando 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Procesando...'),
                    ],
                  )
                : Text(estaEnAgenda ? 'Quitar de Agenda' : 'Agregar a Agenda'),
          ),
        );
      },
    );
  }
  // Replace the _manejarBotonAgendar method
  Future<void> _manejarBotonAgendar(Actividad actividad) async {
    final agendaViewModel = context.read<AgendaViewModel>();
    
    // Si está agregando, calcular recordatorio inteligente
    if (!agendaViewModel.estaEnAgenda(actividad.id)) {
      final ahora = DateTime.now();
      final minutosHastaInicio = actividad.fechaInicio.difference(ahora).inMinutes;
      
      print('=== DEBUG MANEJAR BOTON ===');
      print('DateTime.now(): $ahora');
      print('actividad.fechaInicio: ${actividad.fechaInicio}');
      print('minutosHastaInicio: $minutosHastaInicio');
      
      // CORREGIR: Asegurar que siempre sea mínimo 1 minuto
      final recordatorioMinutos = minutosHastaInicio > 30 
          ? 30 
          : (minutosHastaInicio > 1 ? minutosHastaInicio - 1 : 1);
      
      print('recordatorioMinutos calculado: $recordatorioMinutos');
      print('========================');
      
      agendaViewModel.setRecordatorioTemporal(recordatorioMinutos);
    }

    final exito = await agendaViewModel.alternarActividadEnAgenda(actividad.id);

    if (mounted && exito) {
      final estaEnAgenda = agendaViewModel.estaEnAgenda(actividad.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estaEnAgenda 
              ? 'Actividad agregada a tu agenda' 
              : 'Actividad removida de tu agenda'),
          backgroundColor: estaEnAgenda ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar la solicitud'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
            'Sin actividades programadas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay actividades para ${_formatearDiaCompleto(dia)}',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyDaysState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar días',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudieron cargar los días del evento',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildErrorState(ActividadesViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar actividades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.errorMessage,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarActividades,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1B1B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
  String _formatearDiaTab(DateTime fecha) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${dias[fecha.weekday - 1]} ${fecha.day}/${fecha.month}';
  }
  String _formatearDiaCompleto(DateTime fecha) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }
}