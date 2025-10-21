import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/perfil_service.dart';
import '../services/imgbb_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'historial_inicios_view.dart';

class PerfilUsuarioView extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const PerfilUsuarioView({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<PerfilUsuarioView> createState() => _PerfilUsuarioViewState();
}

class _PerfilUsuarioViewState extends State<PerfilUsuarioView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _usuarioController;
  late TextEditingController _celularController;
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Variables para manejo de imagen de perfil
  File? _nuevaImagenPerfil;
  String? _urlImagenPerfil;
  bool _subiendoImagen = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.userData['username'] ?? widget.userData['usuario'] ?? '',
    );
    _usuarioController = TextEditingController(
      text: widget.userData['username'] ?? widget.userData['usuario'] ?? '',
    );
    _celularController = TextEditingController(
      text: widget.userData['telefono'] ?? widget.userData['celular'] ?? '',
    );
    
    // Inicializar URL de imagen de perfil
    _urlImagenPerfil = widget.userData['imagenPerfil'];
    
    // Cargar datos más actuales desde Firebase
    _cargarDatosActuales();
  }
  
  // Método para cargar los datos más actuales desde Firebase
  Future<void> _cargarDatosActuales() async {
    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('usuarios').doc(widget.userId).get();

      if (userDoc.exists) {
        final datosActualizados = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _usuarioController.text =
              datosActualizados['username']?.toString() ??
              datosActualizados['usuario']?.toString() ??
              '';
          _celularController.text =
              datosActualizados['telefono']?.toString() ??
              datosActualizados['celular']?.toString() ??
              '';
          // Actualizar la imagen de perfil con los datos más recientes
          _urlImagenPerfil = datosActualizados['imagenPerfil'];
        });
      }
    } catch (e) {
      print('Error cargando datos actuales: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  // Método para mostrar opciones de selección de imagen
  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            if (_urlImagenPerfil != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar imagen'),
                onTap: () {
                  Navigator.pop(context);
                  _eliminarImagenPerfil();
                },
              ),
          ],
        ),
      ),
    );
  }

  // Método para seleccionar imagen de galería o cámara
  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (imagen != null) {
        setState(() {
          _nuevaImagenPerfil = File(imagen.path);
        });
        await _subirImagenPerfil();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para subir imagen a ImgBB y actualizar perfil
  Future<void> _subirImagenPerfil() async {
    if (_nuevaImagenPerfil == null) return;

    setState(() => _subiendoImagen = true);

    try {
      // Subir imagen a ImgBB
      final urlImagen = await ImgBBService.subirImagenPerfil(
        _nuevaImagenPerfil!,
        widget.userId,
      );

      if (urlImagen != null) {
        // Actualizar en Firestore
        final success = await PerfilService.actualizarImagenPerfil(
          widget.userId,
          urlImagen,
        );

        if (success) {
          setState(() {
            _urlImagenPerfil = urlImagen;
            _nuevaImagenPerfil = null;
          });

          // Actualizar el AuthViewModel para reflejar los cambios
          if (mounted) {
            final authViewModel = context.read<AuthViewModel>();
            await authViewModel.actualizarUsuario();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Imagen de perfil actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Error al guardar en la base de datos');
        }
      } else {
        throw Exception('Error al subir la imagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  // Método para eliminar imagen de perfil
  Future<void> _eliminarImagenPerfil() async {
    setState(() => _subiendoImagen = true);

    try {
      final success = await PerfilService.actualizarImagenPerfil(
        widget.userId,
        '', // Pasar string vacío para eliminar
      );

      if (success) {
        setState(() {
          _urlImagenPerfil = null;
          _nuevaImagenPerfil = null;
        });

        // Actualizar el AuthViewModel para reflejar los cambios
        if (mounted) {
          final authViewModel = context.read<AuthViewModel>();
          await authViewModel.actualizarUsuario();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Imagen de perfil eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Error al eliminar de la base de datos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final datos = {
      'username': _usuarioController.text.trim(),
      'telefono': _celularController.text.trim(),
    };

    final success = await PerfilService.actualizarDatosBasicos(
      widget.userId,
      datos,
    );

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos actualizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      // Recargar datos para refrescar la UI
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeño delay
      await _recargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al actualizar los datos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isEditable = false,
    TextEditingController? controller,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isEditing && isEditable && controller != null)
                    TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Este campo es requerido';
                        }
                        return null;
                      },
                    )
                  else
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Historial de inicios de sesión',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistorialIniciosView(),
                  ),
                );
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar y información básica
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Avatar con imagen o inicial
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: (_nuevaImagenPerfil != null)
                              ? FileImage(_nuevaImagenPerfil!)
                              : (_urlImagenPerfil != null && _urlImagenPerfil!.isNotEmpty)
                                  ? NetworkImage(_urlImagenPerfil!)
                                  : null,
                          child: (_nuevaImagenPerfil == null && 
                                 (_urlImagenPerfil == null || _urlImagenPerfil!.isEmpty))
                              ? Text(
                                  (_usuarioController.text.isNotEmpty
                                          ? _usuarioController.text
                                          : 'U')
                                      .toString()
                                      .toUpperCase()[0],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                              : null,
                        ),
                        
                        // Indicador de carga y botón de editar
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _subiendoImagen ? null : _mostrarOpcionesImagen,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: _subiendoImagen
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _usuarioController.text.isNotEmpty
                          ? _usuarioController.text
                          : 'Usuario',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        widget.userData['rol'] ?? 'Visitante',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Información del perfil
              _buildInfoCard(
                title: 'Nombre de Usuario',
                subtitle: _usuarioController.text,
                icon: Icons.person,
                isEditable: true,
                controller: _usuarioController,
              ),
              _buildInfoCard(
                title: 'Correo Electrónico',
                subtitle: widget.userData['email'] ?? 'No especificado',
                icon: Icons.email,
                isEditable: false,
              ),
              _buildInfoCard(
                title: 'Número de Celular',
                subtitle:
                    _celularController.text.isEmpty
                        ? 'No especificado'
                        : _celularController.text,
                icon: Icons.phone,
                isEditable: true,
                controller: _celularController,
              ),
              _buildInfoCard(
                title: 'Rol',
                subtitle: widget.userData['rol'] ?? 'Visitante',
                icon: Icons.badge,
                isEditable: false,
              ),

              const SizedBox(height: 32),

              // Botones de acción
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => setState(() => _isEditing = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Guardar Cambios',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recargarDatos() async {
    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('usuarios').doc(widget.userId).get();

      if (userDoc.exists) {
        final datosActualizados = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _usuarioController.text =
              datosActualizados['username']?.toString() ??
              datosActualizados['usuario']?.toString() ??
              '';
          _celularController.text =
              datosActualizados['telefono']?.toString() ??
              datosActualizados['celular']?.toString() ??
              '';
          _urlImagenPerfil = datosActualizados['imagenPerfil'];
        });
      }
    } catch (e) {
      print('Error recargando datos: $e');
    }
  }
}
