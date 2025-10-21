import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class PerfilVisitante extends StatelessWidget {
  const PerfilVisitante({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            final usuario = authViewModel.currentUser;
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Header simple sin imagen
                    Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B1B1B),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Información Personal - Solo lo esencial
                    _buildSeccionInformacion(
                      'Información Personal',
                      Icons.person_outline,
                      [
                        _buildCampoInfo(
                          'Nombre',
                          usuario?.nombre ?? 'No disponible',
                          Icons.account_circle,
                        ),
                        _buildCampoInfo(
                          'Correo',
                          usuario?.correo ?? 'No disponible',
                          Icons.email,
                        ),
                        _buildCampoInfo(
                          'Teléfono',
                          usuario?.telefono ?? 'No disponible',
                          Icons.phone,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Opciones adicionales
                    _buildOpcionMenu(
                      'Ayuda y Soporte',
                      'Obtén ayuda sobre el evento',
                      Icons.help_outline,
                      Colors.blue.shade600,
                      () {
                        // TODO: Implementar ayuda
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildOpcionMenu(
                      'Acerca de PerúFest',
                      'Información sobre el evento',
                      Icons.info_outline,
                      Colors.green.shade600,
                      () {
                        // TODO: Implementar acerca de
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildOpcionMenu(
                      'Cerrar Sesión',
                      'Salir de la aplicación',
                      Icons.logout,
                      Colors.red.shade600,
                      () => _mostrarDialogoCerrarSesion(context, authViewModel),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeccionInformacion(String titulo, IconData icono, List<Widget> campos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: const Color(0xFF8B1B1B),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...campos,
        ],
      ),
    );
  }

  Widget _buildCampoInfo(String etiqueta, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icono,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionMenu(String titulo, String subtitulo, IconData icono, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icono,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _mostrarDialogoCerrarSesion(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '¿Cerrar Sesión?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authViewModel.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}