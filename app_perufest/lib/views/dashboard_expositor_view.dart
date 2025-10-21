import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'perfil_expositor_view.dart';

class DashboardExpositorView extends StatefulWidget {
  const DashboardExpositorView({super.key});

  @override
  State<DashboardExpositorView> createState() => _DashboardExpositorViewState();
}

class _DashboardExpositorViewState extends State<DashboardExpositorView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Usuario no encontrado')),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeView(),
          _buildPerfilView(currentUser),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B1B1B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return const Scaffold(
      appBar: null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 80,
              color: Color(0xFF8B1B1B),
            ),
            SizedBox(height: 16),
            Text(
              'Bienvenido Expositor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1B1B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Dashboard en construcción',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfilView(currentUser) {
    return PerfilExpositorView(
      userId: currentUser.id,
      userData: {
        'username': currentUser.username,
        'email': currentUser.correo,
        'telefono': currentUser.telefono,
        'rol': currentUser.rol,
        'imagenPerfil': currentUser.imagenPerfil,
        'empresa': currentUser.toJson()['empresa'] ?? {},
        'redes_sociales': currentUser.toJson()['redes_sociales'] ?? {},
      },
    );
  }
}
