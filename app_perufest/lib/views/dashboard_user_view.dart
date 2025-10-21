import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/evento.dart';
import '../viewmodels/eventos_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'visitante/evento_opciones_view.dart';
import 'perfil_usuario_view.dart';
import 'visitante/mapa_view.dart';

class DashboardUserView extends StatefulWidget {
  const DashboardUserView({super.key});

  @override
  State<DashboardUserView> createState() => _DashboardUserViewState();
}

class _DashboardUserViewState extends State<DashboardUserView> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Color> _eventoColors = [
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
    const Color(0xFFB22222), // Firebrick
    const Color(0xFF8B4513), // Saddle brown
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventos();
    });
  }

  Future<void> _cargarEventos() async {
    final eventosViewModel = context.read<EventosViewModel>();
    await eventosViewModel.cargarEventos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [_buildEventosPage(), _buildMapaPage(), _buildPerfilPage()],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEventosPage() {
    return Consumer<EventosViewModel>(
      builder: (context, eventosViewModel, child) {
        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (eventosViewModel.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (eventosViewModel.eventos.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              _buildEventosList(eventosViewModel.eventos),
          ],
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF8B1B1B),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'PerúFest 2025',
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
                right: -50,
                top: -50,
                child: Icon(
                  Icons.festival,
                  size: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              const Positioned(
                bottom: 60,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido al',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      'Parque Perú',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventosList(List<Evento> eventos) {
    // Filtrar solo eventos activos
    final eventosActivos = eventos.where((e) => e.estado == 'activo').toList();

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 16.0,
          childAspectRatio: 2.2, // Aumentado de 2.0 a 2.2 para dar más altura
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final evento = eventosActivos[index];
          final color = _eventoColors[index % _eventoColors.length];
          return _buildEventoCard(evento, color);
        }, childCount: eventosActivos.length),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento, Color color) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final inicioEvento = DateTime(
      evento.fechaInicio.year,
      evento.fechaInicio.month,
      evento.fechaInicio.day,
    );
    final finEvento = DateTime(
      evento.fechaFin.year,
      evento.fechaFin.month,
      evento.fechaFin.day,
    );

    String estadoTexto = '';
    Color estadoColor = color;

    if (hoy.isAtSameMomentAs(inicioEvento) ||
        (hoy.isAfter(inicioEvento) && hoy.isBefore(finEvento)) ||
        hoy.isAtSameMomentAs(finEvento)) {
      estadoTexto = 'ACTUAL';
      estadoColor = Colors.green;
    } else if (inicioEvento.isAfter(hoy)) {
      final diasRestantes = inicioEvento.difference(hoy).inDays;
      if (diasRestantes <= 7) {
        estadoTexto = 'PRÓXIMO';
        estadoColor = Colors.orange;
      }
    }

    return GestureDetector(
      onTap: () => _verActividadesEvento(evento),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Patrón decorativo de fondo
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.celebration,
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Solo badge de estado si existe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (estadoTexto.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              estadoTexto,
                              style: TextStyle(
                                color: estadoColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Título del evento
                    Text(
                      evento.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Color.fromARGB(127, 0, 0, 0),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Categoría del evento
                    Text(
                      evento.categoria,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Información de fechas y ubicación
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_formatearFecha(evento.fechaInicio)} - ${_formatearFecha(evento.fechaFin)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                evento.lugar,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                          ],
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
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
            'Los eventos aparecerán aquí cuando estén disponibles',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarEventos,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1B1B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilPage() {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Error: Usuario no encontrado'));
    }

    return PerfilUsuarioView(
      userId: currentUser.id,
      userData: {
        'username': currentUser.username,
        'email': currentUser.correo,
        'telefono': currentUser.telefono,
        'rol': currentUser.rol,
        'imagenPerfil': currentUser.imagenPerfil,
      },
    );
  }

  Widget _buildMapaPage() {
    return const MapaView();
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            _mostrarMenuCerrarSesion();
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF8B1B1B),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration),
            activeIcon: Icon(Icons.celebration),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            activeIcon: Icon(Icons.logout),
            label: 'Salir',
          ),
        ],
      ),
    );
  }

  void _mostrarMenuCerrarSesion() {
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
                Icon(Icons.logout, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  '¿Cerrar Sesión?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se cerrará tu sesión y regresarás a la pantalla de inicio',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _cerrarSesion();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cerrar Sesión'),
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

  void _cerrarSesion() async {
    final authViewModel = context.read<AuthViewModel>();
    authViewModel.logout();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _verActividadesEvento(Evento evento) {
    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EventoOpcionesView(evento: evento, userId: currentUserId),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
