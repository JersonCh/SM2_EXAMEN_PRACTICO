import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stands_viewmodel.dart';

class CrearStandPage extends StatefulWidget {
  const CrearStandPage({super.key});

  @override
  State<CrearStandPage> createState() => _CrearStandPageState();
}

class _CrearStandPageState extends State<CrearStandPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Limpiar el formulario al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StandsViewModel>().limpiarError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Stand'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: Consumer<StandsViewModel>(
        builder: (context, standsViewModel, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Información del evento y zona seleccionados
                _buildInfoSeleccion(standsViewModel),
                const SizedBox(height: 24),

                // Información básica del stand
                _buildSeccionBasica(standsViewModel),
                const SizedBox(height: 24),

                // Información de contacto
                _buildSeccionContacto(standsViewModel),
                const SizedBox(height: 24),

                // Productos/Servicios
                _buildSeccionProductos(standsViewModel),
                const SizedBox(height: 24),

                // Imagen
                _buildSeccionImagen(standsViewModel),
                const SizedBox(height: 32),

                // Mostrar error si existe
                if (standsViewModel.error.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            standsViewModel.error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Botones de acción
                _buildBotonesAccion(standsViewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSeleccion(StandsViewModel standsViewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubicación del Stand',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1B1B),
              ),
            ),
            const SizedBox(height: 12),
            if (standsViewModel.eventoSeleccionado != null) ...[
              Row(
                children: [
                  const Icon(Icons.event, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Evento: ${standsViewModel.eventoSeleccionado!.nombre}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (standsViewModel.zonaSeleccionada != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zona: ${standsViewModel.zonaSeleccionada!.nombre}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionBasica(StandsViewModel standsViewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1B1B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: standsViewModel.nombreEmpresaController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Empresa *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre de la empresa es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: standsViewModel.descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Describe brevemente lo que ofrece la empresa',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionContacto(StandsViewModel standsViewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1B1B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: standsViewModel.contactoController,
              decoration: const InputDecoration(
                labelText: 'Persona de Contacto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: standsViewModel.telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: 'Ej: 987654321',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionProductos(StandsViewModel standsViewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos/Servicios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1B1B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: standsViewModel.productosController,
              decoration: const InputDecoration(
                labelText: 'Productos o Platos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
                hintText: 'Ej: Ceviche, Ají de gallina, Lomo saltado',
                helperText: 'Separe los productos con comas (,)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionImagen(StandsViewModel standsViewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imagen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1B1B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: standsViewModel.imagenUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de la Imagen (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
                hintText: 'https://ejemplo.com/imagen.jpg',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nota: La funcionalidad de subir imágenes se implementará en una versión futura',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion(StandsViewModel standsViewModel) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: standsViewModel.isLoading ? null : () {
              if (_formKey.currentState!.validate()) {
                _crearStand(standsViewModel);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1B1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: standsViewModel.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Crear Stand',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: standsViewModel.isLoading ? null : () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF8B1B1B)),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, color: Color(0xFF8B1B1B)),
            ),
          ),
        ),
      ],
    );
  }

  void _crearStand(StandsViewModel standsViewModel) async {
    await standsViewModel.agregarStand();
    
    if (standsViewModel.error.isEmpty && mounted) {
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stand creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Volver a la página anterior
      Navigator.pop(context);
    }
  }
}