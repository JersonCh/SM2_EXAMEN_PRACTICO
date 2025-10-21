import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/historial_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/registro_inicio.dart';

class HistorialIniciosView extends StatefulWidget {
  const HistorialIniciosView({super.key});

  @override
  State<HistorialIniciosView> createState() => _HistorialIniciosViewState();
}

class _HistorialIniciosViewState extends State<HistorialIniciosView> {
  late HistorialViewModel _historialViewModel;

  @override
  void initState() {
    super.initState();
    _historialViewModel = HistorialViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarHistorial();
    });
  }

  void _cargarHistorial() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.currentUser != null) {
      _historialViewModel.cargarHistorial(authViewModel.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historial de Inicios de Sesión',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _cargarHistorial,
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _historialViewModel,
        child: Consumer<HistorialViewModel>(
          builder: (context, historialVM, child) {
            if (historialVM.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
                ),
              );
            }

            if (historialVM.state == HistorialState.error) {
              return _buildErrorState(historialVM.errorMessage);
            }

            if (historialVM.registros.isEmpty) {
              return _buildEmptyState();
            }

            return _buildHistorialList(historialVM.registros);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el historial',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _cargarHistorial,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay historial disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los inicios de sesión aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialList(List<RegistroInicio> registros) {
    return RefreshIndicator(
      onRefresh: () async => _cargarHistorial(),
      color: const Color(0xFF8B0000),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: registros.length,
        itemBuilder: (context, index) {
          final registro = registros[index];
          return _buildRegistroCard(registro, index == 0);
        },
      ),
    );
  }

  Widget _buildRegistroCard(RegistroInicio registro, bool isRecent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRecent ? const Color(0xFF8B0000).withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecent ? const Color(0xFF8B0000).withOpacity(0.2) : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isRecent ? const Color(0xFF8B0000) : Colors.grey[400],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            _getDispositivoIcon(registro.dispositivoInfo),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          _historialViewModel.formatearFecha(registro.fechaInicio),
          style: TextStyle(
            fontWeight: isRecent ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
            color: isRecent ? const Color(0xFF8B0000) : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              registro.dispositivoInfo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (registro.direccionIP != null) ...[
              const SizedBox(height: 2),
              Text(
                'IP: ${registro.direccionIP}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: isRecent 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Reciente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      ),
    );
  }

  IconData _getDispositivoIcon(String dispositivoInfo) {
    if (dispositivoInfo.toLowerCase().contains('android')) {
      return Icons.android;
    } else if (dispositivoInfo.toLowerCase().contains('ios')) {
      return Icons.phone_iphone;
    } else if (dispositivoInfo.toLowerCase().contains('windows')) {
      return Icons.computer;
    } else if (dispositivoInfo.toLowerCase().contains('mac')) {
      return Icons.laptop_mac;
    } else if (dispositivoInfo.toLowerCase().contains('linux')) {
      return Icons.laptop;
    }
    return Icons.devices;
  }

  @override
  void dispose() {
    _historialViewModel.dispose();
    super.dispose();
  }
}