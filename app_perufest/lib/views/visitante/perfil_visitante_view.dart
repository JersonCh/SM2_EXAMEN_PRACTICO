import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class PerfilVisitanteView extends StatelessWidget {
  const PerfilVisitanteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final usuario = authViewModel.currentUser;
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildProfileSection(usuario),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B1B1B),
            const Color(0xFF8B1B1B).withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Icon(
            Icons.person,
            size: 90,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(dynamic usuario) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
                Icons.info_outline,
                color: const Color(0xFF8B1B1B),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nombre', usuario?.nombre ?? 'Visitante Anónimo'),
          _buildInfoRow('Email', usuario?.correo ?? 'No especificado'),
          _buildInfoRow('Teléfono', usuario != null && usuario.telefono.isNotEmpty ? usuario.telefono : 'No especificado'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

}