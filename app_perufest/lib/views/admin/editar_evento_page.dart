import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/evento.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import '../../services/validador_service.dart';
import '../../services/imgbb_service.dart';
import '../../services/timezone.dart';
import 'dart:io';


class EditarEventoPage extends StatefulWidget {
  final Evento evento;

  const EditarEventoPage({super.key, required this.evento});

  @override
  State<EditarEventoPage> createState() => _EditarEventoPageState();
}

class _EditarEventoPageState extends State<EditarEventoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _organizadorController = TextEditingController();
  final _lugarController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  String _categoriaSeleccionada = 'Ferias y Exposiciones';
  String _estadoSeleccionado = 'activo';
  DateTime? _fechaInicio;
  TimeOfDay? _horaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaFin;
  File? _nuevaImagenSeleccionada;
  bool _subiendoImagen = false;
  bool _imagenCambiada = false;

  final List<String> _categorias = [
    'Ferias y Exposiciones',
    'Festivales Culturales',
    'Conciertos'
  ];

  final List<String> _estados = [
    'activo',
    'cancelado',
    'finalizado'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosEvento();
  }

void _cargarDatosEvento() {
  final evento = widget.evento;
  _nombreController.text = evento.nombre;
  _descripcionController.text = evento.descripcion;
  _organizadorController.text = evento.organizador;
  _lugarController.text = evento.lugar;
  _imagenUrlController.text = evento.imagenUrl;
  _categoriaSeleccionada = evento.categoria;
  _estadoSeleccionado = evento.estado;
  
  // Convert to Peru timezone for display  
  final fechaInicioPeruana = TimezoneUtils.toPeru(evento.fechaInicio);
  final fechaFinPeruana = TimezoneUtils.toPeru(evento.fechaFin);
  
  _fechaInicio = DateTime(fechaInicioPeruana.year, fechaInicioPeruana.month, fechaInicioPeruana.day);
  _fechaFin = DateTime(fechaFinPeruana.year, fechaFinPeruana.month, fechaFinPeruana.day);
  _horaInicio = TimeOfDay.fromDateTime(fechaInicioPeruana);
  _horaFin = TimeOfDay.fromDateTime(fechaFinPeruana);
}

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _organizadorController.dispose();
    _lugarController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _mostrarInformacionEvento(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del evento
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editando: ${widget.evento.nombre}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Creado por: ${widget.evento.creadoPor}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Creado: ${_formatearFecha(widget.evento.fechaCreacion)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Estado del evento
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado del Evento *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: _estados.map((estado) => DropdownMenuItem(
                      value: estado,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getColorEstado(estado),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(estado.toUpperCase()),
                        ],
                      ),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _estadoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

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
                decoration: const InputDecoration(
                  labelText: 'Lugar *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => ValidadorService.validarCampoRequerido(value, 'Lugar'),
              ),
              const SizedBox(height: 16),

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
                          Text('Imagen del Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Mostrar imagen (nueva o actual)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _nuevaImagenSeleccionada != null
                              ? Image.file(_nuevaImagenSeleccionada!, fit: BoxFit.cover)
                              : widget.evento.imagenUrl.isNotEmpty
                                  ? Image.network(widget.evento.imagenUrl, fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                          const Center(child: Icon(Icons.broken_image, size: 48)))
                                  : Container(
                                      color: Colors.grey.shade50,
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                            Text('Sin imagen'),
                                          ],
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _seleccionarNuevaImagen,
                              style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                              child: const Text('Cambiar imagen'),
                            ),
                          ),
                          if (_nuevaImagenSeleccionada != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() {
                                  _nuevaImagenSeleccionada = null;
                                  _imagenCambiada = false;
                                }),
                                style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                                child: const Text('Restaurar'),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      if (_subiendoImagen)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          color: Colors.blue.shade50,
                          child: const Row(
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Subiendo imagen...'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Atrás'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Consumer<EventosViewModel>(
                        builder: (context, viewModel, child) {
                          final estaOcupado = viewModel.isLoading || _subiendoImagen;
                          return ElevatedButton.icon(
                            onPressed: estaOcupado ? null : _actualizarEvento, // <-- usa estaOcupado
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: estaOcupado
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
                                ),
                              )
                              :const Icon(Icons.save),
                            label: const Text('Guardar Cambios'),
                          );
                        },
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
  bool _pickerActivo = false;
  Future<void> _seleccionarNuevaImagen() async {
    if (_pickerActivo) return; // Evita abrir dos veces
    setState(() {
      _pickerActivo = true;
    });

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
            _nuevaImagenSeleccionada = File(imagen.path);
            _imagenCambiada = true;
          });
        }
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    } finally {
      setState(() {
        _pickerActivo = false;
      });
    }
  }

  Future<String?> _subirNuevaImagenSiEsNecesario() async {
    if (!_imagenCambiada) return widget.evento.imagenUrl;
    if (_nuevaImagenSeleccionada == null) return widget.evento.imagenUrl;

    setState(() => _subiendoImagen = true);
    
    try {
      return await ImgBBService.subirImagenFormData(_nuevaImagenSeleccionada!);
    } catch (e) {
      _mostrarError('Error al subir imagen: $e');
      return null;
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio ?? TimezoneUtils.today() : _fechaFin ?? TimezoneUtils.today(),
      firstDate: TimezoneUtils.today().subtract(const Duration(days: 365)),
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
    final ahora = TimezoneUtils.now();
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: esInicio 
          ? _horaInicio ?? TimeOfDay.fromDateTime(ahora)
          : _horaFin ?? TimeOfDay.fromDateTime(ahora),
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

  Future<void> _actualizarEvento() async {
    if (!_validarFormulario()) return;

    final eventosViewModel = Provider.of<EventosViewModel>(context, listen: false);

    // Use TimezoneUtils instead of DateTime
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

    String? imagenUrlFinal = await _subirNuevaImagenSiEsNecesario();
    if (_imagenCambiada && _nuevaImagenSeleccionada != null && imagenUrlFinal == null) {
      return; // Error al subir imagen
    }

    final eventoActualizado = widget.evento.copyWith(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      organizador: _organizadorController.text.trim(),
      categoria: _categoriaSeleccionada,
      fechaInicio: fechaInicioCompleta,
      fechaFin: fechaFinCompleta,
      lugar: _lugarController.text.trim(),
      imagenUrl: imagenUrlFinal ?? widget.evento.imagenUrl,
      estado: _estadoSeleccionado,
      fechaActualizacion: TimezoneUtils.now(), // Use TimezoneUtils
    );

    final exito = await eventosViewModel.actualizarEvento(widget.evento.id, eventoActualizado);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento actualizado correctamente')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(eventosViewModel.errorMessage)),
      );
    }
  }

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

  // Use TimezoneUtils instead of DateTime
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

  void _mostrarInformacionEvento() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ID:', widget.evento.id),
            _buildInfoRow('Creado por:', widget.evento.creadoPor),
            _buildInfoRow('Fecha creación:', _formatearFecha(widget.evento.fechaCreacion)),
            _buildInfoRow('Última actualización:', _formatearFecha(widget.evento.fechaActualizacion)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$titulo ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'activo':
        return Colors.green;
      case 'cancelado':
        return Colors.orange;
      case 'finalizado':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}