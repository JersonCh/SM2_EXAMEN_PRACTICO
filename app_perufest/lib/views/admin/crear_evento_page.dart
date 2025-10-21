import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/evento.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/validador_service.dart';
import '../../services/imgbb_service.dart';
import '../../services/timezone.dart';

class CrearEventoPage extends StatefulWidget {
  const CrearEventoPage({super.key});

  @override
  State<CrearEventoPage> createState() => _CrearEventoPageState();
}

class _CrearEventoPageState extends State<CrearEventoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _organizadorController = TextEditingController();
  final _lugarController = TextEditingController();

  String _categoriaSeleccionada = 'Ferias y Exposiciones';
  DateTime? _fechaInicio;
  TimeOfDay? _horaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaFin;
  
  // Variables para imagen
  File? _imagenSeleccionada;
  bool _subiendoImagen = false;

  final List<String> _categorias = [
    'Ferias y Exposiciones',
    'Festivales Culturales',
    'Conciertos'
  ];

  @override
  void initState() {
    super.initState();
    _lugarController.text = 'Parque Perú'; // Valor por defecto
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _organizadorController.dispose();
    _lugarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre del evento
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Evento *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) => ValidadorService.validarCampoRequerido(value, 'Nombre'),
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) => ValidadorService.validarCampoRequerido(value, 'Descripción'),
              ),
              const SizedBox(height: 16),

              // Organizador
              TextFormField(
                controller: _organizadorController,
                decoration: const InputDecoration(
                  labelText: 'Organizador *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => ValidadorService.validarCampoRequerido(value, 'Organizador'),
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias.map((categoria) => DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Fecha y hora de inicio
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFecha(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha Inicio *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        child: Text(
                          _fechaInicio != null
                              ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                              : 'Seleccionar fecha',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarHora(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora Inicio *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _horaInicio != null
                              ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}'
                              : 'Hora',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fecha y hora de fin
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFecha(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha Fin *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        child: Text(
                          _fechaFin != null
                              ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                              : 'Seleccionar fecha',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarHora(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora Fin *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _horaFin != null
                              ? '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}'
                              : 'Hora',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lugar
              TextFormField(
                controller: _lugarController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Lugar *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => ValidadorService.validarCampoRequerido(value, 'Lugar'),
              ),
              const SizedBox(height: 16),

              // Selector de imagen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.image, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Imagen del Evento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_imagenSeleccionada != null) ...[
                        // Mostrar imagen seleccionada
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imagenSeleccionada!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _cambiarImagen,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Cambiar imagen'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _eliminarImagen,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                icon: const Icon(Icons.delete),
                                label: const Text('Quitar'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Botón para seleccionar imagen
                        InkWell(
                          onTap: _seleccionarImagen,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para seleccionar imagen',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(Opcional)',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_subiendoImagen) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Subiendo imagen...'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón crear evento
              SafeArea(
                child: Consumer<EventosViewModel>(
                  builder: (context, viewModel, child) {
                    final estaOcupado = viewModel.isLoading || _subiendoImagen;
                    return ElevatedButton(
                      onPressed: estaOcupado ? null : _crearEvento,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: estaOcupado
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_subiendoImagen 
                                    ? 'Subiendo imagen...' 
                                    : 'Creando evento...'),
                              ],
                            )
                          : const Text('Crear Evento'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Mostrar opciones de selección
      final opcion = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

      if (opcion != null) {
        final XFile? imagen = await picker.pickImage(
          source: opcion == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (imagen != null) {
          setState(() {
            _imagenSeleccionada = File(imagen.path);
// Limpiar URL anterior si existía
          });
        }
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _cambiarImagen() async {
    await _seleccionarImagen();
  }

  void _eliminarImagen() {
    setState(() {
      _imagenSeleccionada = null;
    });
  }

  Future<String?> _subirImagenSiEsNecesario() async {
    if (_imagenSeleccionada == null) {
      return null; // No hay imagen para subir
    }

    setState(() {
      _subiendoImagen = true;
    });

    try {
      final url = await ImgBBService.subirImagenFormData(_imagenSeleccionada!);
      return url;
    } catch (e) {
      _mostrarError('Error al subir imagen: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _subiendoImagen = false;
        });
      }
    }
  }
  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: TimezoneUtils.today(),
      firstDate: TimezoneUtils.today(),
      lastDate: TimezoneUtils.today().add(const Duration(days: 365)),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fechaSeleccionada;
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
    }
  }

  Future<void> _seleccionarHora(BuildContext context, bool esInicio) async {
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = horaSeleccionada;
        } else {
          _horaFin = horaSeleccionada;
        }
      });
    }
  }

  // Replace the _crearEvento method
  Future<void> _crearEvento() async {
    if (!_validarFormulario()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    // Subir imagen si hay una seleccionada
    String? imagenUrl;
    if (_imagenSeleccionada != null) {
      imagenUrl = await _subirImagenSiEsNecesario();
      if (imagenUrl == null) return;
    }

    // Usar TimezoneUtils
    final fechaInicioCompleta = TimezoneUtils.create(
      _fechaInicio!.year,
      _fechaInicio!.month,
      _fechaInicio!.day,
      _horaInicio!.hour,
      _horaInicio!.minute,
    );

    final fechaFinCompleta = TimezoneUtils.create(
      _fechaFin!.year,
      _fechaFin!.month,
      _fechaFin!.day,
      _horaFin!.hour,
      _horaFin!.minute,
    );

    final evento = Evento(
      id: '',
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      organizador: _organizadorController.text.trim(),
      categoria: _categoriaSeleccionada,
      fechaInicio: fechaInicioCompleta,
      fechaFin: fechaFinCompleta,
      lugar: _lugarController.text.trim(),
      imagenUrl: imagenUrl ?? '',
      creadoPor: currentUser.username,
      estado: 'activo',
      fechaCreacion: TimezoneUtils.now(),
      fechaActualizacion: TimezoneUtils.now(),
    );

    final eventosViewModel = Provider.of<EventosViewModel>(context, listen: false);
    final exito = await eventosViewModel.crearEvento(evento);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento creado correctamente')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(eventosViewModel.errorMessage)),
      );
    }
  }

  // Replace the _validarFormulario method
  bool _validarFormulario() {
    if (!_formKey.currentState!.validate()) return false;

    if (_fechaInicio == null) {
      _mostrarError('Selecciona la fecha de inicio');
      return false;
    }

    if (_horaInicio == null) {
      _mostrarError('Selecciona la hora de inicio');
      return false;
    }

    if (_fechaFin == null) {
      _mostrarError('Selecciona la fecha de fin');
      return false;
    }

    if (_horaFin == null) {
      _mostrarError('Selecciona la hora de fin');
      return false;
    }

    final fechaInicioCompleta = TimezoneUtils.create(
      _fechaInicio!.year,
      _fechaInicio!.month,
      _fechaInicio!.day,
      _horaInicio!.hour,
      _horaInicio!.minute,
    );

    final fechaFinCompleta = TimezoneUtils.create(
      _fechaFin!.year,
      _fechaFin!.month,
      _fechaFin!.day,
      _horaFin!.hour,
      _horaFin!.minute,
    );

    if (fechaFinCompleta.isBefore(fechaInicioCompleta)) {
      _mostrarError('La fecha de fin debe ser posterior a la fecha de inicio');
      return false;
    }

    return true;
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}

