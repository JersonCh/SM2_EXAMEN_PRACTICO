import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/perfil_service.dart';
import '../services/imgbb_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'historial_inicios_view.dart';

class PerfilExpositorView extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const PerfilExpositorView({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<PerfilExpositorView> createState() => _PerfilExpositorViewState();
}

class _PerfilExpositorViewState extends State<PerfilExpositorView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores básicos
  final _usuarioController = TextEditingController();
  final _celularController = TextEditingController();

  // Controladores para empresa
  final _nombreEmpresaController = TextEditingController();
  final _descripcionEmpresaController = TextEditingController();

  // Estado
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, String> redesSociales = {};

  // Variables para manejo de imagen de perfil
  File? _nuevaImagenPerfil;
  String? _urlImagenPerfil;
  bool _subiendoImagen = false;
  final ImagePicker _picker = ImagePicker();

  // Opciones de redes sociales disponibles
  final List<Map<String, dynamic>> opcionesRedes = [
    {'nombre': 'Facebook', 'icon': Icons.facebook, 'color': Color(0xFF1877F2)},
    {'nombre': 'WhatsApp', 'icon': Icons.phone, 'color': Color(0xFF25D366)},
    {
      'nombre': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE4405F),
    },
    {'nombre': 'TikTok', 'icon': Icons.music_note, 'color': Color(0xFF000000)},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _limpiarDuplicados();
  }

  Future<void> _limpiarDuplicados() async {
    // Limpiar campos duplicados en segundo plano
    try {
      await PerfilService.limpiarCamposDuplicados(widget.userId);
    } catch (e) {
      print('Error limpiando duplicados: $e');
    }
  }

  void _initControllers() {
    try {
      // Datos básicos - usar nombres consistentes con el registro
      _usuarioController.text =
          widget.userData['username']?.toString() ??
          widget.userData['usuario']?.toString() ??
          '';
      _celularController.text =
          widget.userData['telefono']?.toString() ??
          widget.userData['celular']?.toString() ??
          '';

      // Datos de empresa
      final empresa = widget.userData['empresa'] as Map<String, dynamic>? ?? {};
      _nombreEmpresaController.text = empresa['nombre']?.toString() ?? '';
      _descripcionEmpresaController.text =
          empresa['descripcion']?.toString() ?? '';

      // Redes sociales
      final redes =
          widget.userData['redes_sociales'] as Map<String, dynamic>? ?? {};
      redesSociales = Map<String, String>.from(redes);
      
      // Imagen de perfil
      _urlImagenPerfil = widget.userData['imagenPerfil'];
      
      // Cargar datos más actuales desde Firebase
      _cargarDatosActuales();
    } catch (e) {
      print('Error inicializando controladores: $e');
    }
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
          
          // Actualizar datos de empresa
          final empresa =
              datosActualizados['empresa'] as Map<String, dynamic>? ?? {};
          _nombreEmpresaController.text = empresa['nombre']?.toString() ?? '';
          _descripcionEmpresaController.text =
              empresa['descripcion']?.toString() ?? '';

          // Actualizar redes sociales
          final redes =
              datosActualizados['redes_sociales'] as Map<String, dynamic>? ??
              {};
          redesSociales = Map<String, String>.from(redes);
          
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
    _usuarioController.dispose();
    _celularController.dispose();
    _nombreEmpresaController.dispose();
    _descripcionEmpresaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Datos básicos del usuario
      final datosBasicos = {
        'username': _usuarioController.text.trim(),
        'telefono': _celularController.text.trim(),
      };

      // Datos de empresa (solo nombre y descripción)
      final datosEmpresa = {
        'nombre': _nombreEmpresaController.text.trim(),
        'descripcion': _descripcionEmpresaController.text.trim(),
      };

      // Actualizar datos básicos
      bool successBasicos = await PerfilService.actualizarDatosBasicos(
        widget.userId,
        datosBasicos,
      );

      // Actualizar datos de empresa
      bool successEmpresa = await PerfilService.actualizarDatosEmpresa(
        widget.userId,
        datosEmpresa,
      );

      if (successBasicos && successEmpresa) {
        setState(() => _isEditing = false);
        _mostrarMensaje('Datos actualizados exitosamente', esError: false);

        // Recargar datos desde la base de datos para refrescar la UI
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Pequeño delay
        await _recargarDatos();
      } else {
        _mostrarMensaje('Error al actualizar algunos datos');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _agregarRedSocial(String nombre, String url) async {
    if (url.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa la URL de tu $nombre');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success = await PerfilService.agregarRedSocial(
        widget.userId,
        nombre,
        url.trim(),
      );

      if (success) {
        setState(() {
          redesSociales[nombre] = url.trim();
        });
        _mostrarMensaje('$nombre agregado exitosamente', esError: false);
      } else {
        _mostrarMensaje('Error al agregar $nombre');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _eliminarRedSocial(String nombre) async {
    setState(() => _isLoading = true);

    try {
      bool success = await PerfilService.eliminarRedSocial(
        widget.userId,
        nombre,
      );

      if (success) {
        setState(() {
          redesSociales.remove(nombre);
        });
        _mostrarMensaje('$nombre eliminado exitosamente', esError: false);
      } else {
        _mostrarMensaje('Error al eliminar $nombre');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _mostrarMensaje(String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
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
              leading: const Icon(Icons.photo_library, color: Color(0xFF8B1B1B)),
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
      _mostrarMensaje('Error al seleccionar imagen: $e');
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

          _mostrarMensaje('Imagen de perfil actualizada', esError: false);
        } else {
          throw Exception('Error al guardar en la base de datos');
        }
      } else {
        throw Exception('Error al subir la imagen');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e');
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

        _mostrarMensaje('Imagen de perfil eliminada', esError: false);
      } else {
        throw Exception('Error al eliminar de la base de datos');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e');
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil - Expositor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B1B1B),
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
          if (_isEditing) ...[
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed:
                _isEditing
                    ? _guardarCambios
                    : () => setState(() => _isEditing = true),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatosPersonales(),
                      const SizedBox(height: 24),
                      _buildInfoEmpresa(),
                      const SizedBox(height: 24),
                      _buildRedesSociales(),
                      if (_isEditing) ...[
                        const SizedBox(height: 32),
                        _buildBotonGuardar(),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDatosPersonales() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: const Color(0xFF8B1B1B)),
                const SizedBox(width: 8),
                const Text(
                  'Datos Personales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Avatar con imagen de perfil
            Center(
              child: Stack(
                children: [
                  // Avatar con imagen o inicial
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
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
                                    : 'E')
                                .toString()
                                .toUpperCase()[0],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B1B1B),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1B1B),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: _subiendoImagen
                            ? const SizedBox(
                                width: 12,
                                height: 12,
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
                                size: 12,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _usuarioController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Nombre de Usuario',
                prefixIcon: Icon(Icons.account_circle),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _celularController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Celular',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.userData['email']?.toString() ?? '',
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoEmpresa() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: const Color(0xFF8B1B1B)),
                const SizedBox(width: 8),
                const Text(
                  'Información de Empresa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreEmpresaController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Empresa',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
                hintText: 'Ej: Mi Empresa S.A.C.',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionEmpresaController,
              enabled: _isEditing,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción de la Empresa',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                hintText: 'Describe tu empresa y sus servicios...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedesSociales() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: const Color(0xFF8B1B1B)),
                const SizedBox(width: 8),
                const Text(
                  'Redes Sociales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botones para agregar redes sociales
            if (_isEditing) ...[
              const Text(
                'Selecciona la red social que deseas agregar:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    opcionesRedes.map((opcion) {
                      final String nombre = opcion['nombre'];
                      final IconData icon = opcion['icon'];
                      final Color color = opcion['color'];
                      final bool yaAgregada = redesSociales.containsKey(nombre);

                      return ElevatedButton.icon(
                        onPressed:
                            yaAgregada
                                ? null
                                : () => _mostrarDialogoRedSocial(
                                  nombre,
                                  icon,
                                  color,
                                ),
                        icon: Icon(icon, size: 18),
                        label: Text(nombre),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yaAgregada ? Colors.grey : color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Lista de redes sociales existentes
            if (redesSociales.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'No hay redes sociales agregadas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...redesSociales.entries.map((entry) {
                final opcion = opcionesRedes.firstWhere(
                  (op) => op['nombre'] == entry.key,
                  orElse:
                      () => {
                        'nombre': entry.key,
                        'icon': Icons.link,
                        'color': Colors.grey,
                      },
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: opcion['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        opcion['icon'],
                        color: opcion['color'],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      entry.value,
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                        _isEditing
                            ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  () => _confirmarEliminarRedSocial(entry.key),
                            )
                            : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoRedSocial(String nombre, IconData icon, Color color) {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text('Agregar $nombre'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ingresa tu enlace de $nombre:'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'URL de $nombre',
                    hintText: _getHintUrl(nombre),
                    prefixIcon: Icon(Icons.link),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (urlController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    _agregarRedSocial(nombre, urlController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agregar'),
              ),
            ],
          ),
    );
  }

  String _getHintUrl(String nombre) {
    switch (nombre) {
      case 'Facebook':
        return 'https://www.facebook.com/tu-pagina';
      case 'WhatsApp':
        return 'https://wa.me/51987654321';
      case 'Instagram':
        return 'https://www.instagram.com/tu-cuenta';
      case 'TikTok':
        return 'https://www.tiktok.com/@tu-cuenta';
      default:
        return 'https://...';
    }
  }

  void _confirmarEliminarRedSocial(String nombre) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Red Social'),
            content: Text('¿Estás seguro de que quieres eliminar $nombre?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _eliminarRedSocial(nombre);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _guardarCambios,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B1B1B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  Future<void> _recargarDatos() async {
    try {
      // Importar Firestore para recargar los datos
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('usuarios').doc(widget.userId).get();

      if (userDoc.exists) {
        final datosActualizados = userDoc.data() as Map<String, dynamic>;

        // Actualizar los controladores con los nuevos datos
        setState(() {
          _usuarioController.text =
              datosActualizados['username']?.toString() ??
              datosActualizados['usuario']?.toString() ??
              '';
          _celularController.text =
              datosActualizados['telefono']?.toString() ??
              datosActualizados['celular']?.toString() ??
              '';

          // Actualizar datos de empresa
          final empresa =
              datosActualizados['empresa'] as Map<String, dynamic>? ?? {};
          _nombreEmpresaController.text = empresa['nombre']?.toString() ?? '';
          _descripcionEmpresaController.text =
              empresa['descripcion']?.toString() ?? '';

          // Actualizar redes sociales
          final redes =
              datosActualizados['redes_sociales'] as Map<String, dynamic>? ??
              {};
          redesSociales = Map<String, String>.from(redes);
          
          // Actualizar imagen de perfil
          _urlImagenPerfil = datosActualizados['imagenPerfil'];
        });
      }
    } catch (e) {
      print('Error recargando datos: $e');
    }
  }
}
