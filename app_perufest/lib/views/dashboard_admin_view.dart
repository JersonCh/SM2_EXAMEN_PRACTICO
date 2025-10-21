import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin/noticias_page.dart';
import 'admin/eventos_page.dart';
import 'admin/actividades_page.dart';
import 'admin/stands_page.dart';
import 'admin/estadisticas_page.dart';
import 'admin/mapa_admin_view.dart';
import 'perfil_administrador_view.dart';
import '../viewmodels/auth_viewmodel.dart';

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> {
  int _currentIndex = 0;

  // Lista de páginas para cada tab
  final List<Widget> _pages = [
    const NoticiasPage(),
    const EventosPage(),
    const ActividadesPage(),
    const StandsPage(),
    const MapaAdminView(),
    const EstadisticasPage(),
  ];

  Widget _buildPerfilPage() {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Error: Usuario no encontrado'));
    }

    return PerfilAdministradorView(
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Usar tu método logout existente
                  context.read<AuthViewModel>().logout();
                  Navigator.pop(context);
                  // Navegar al login
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 6 ? _buildPerfilPage() : _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFF8B1B1B),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Noticias'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_activity),
            label: 'Actividades',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stands'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Zonas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
