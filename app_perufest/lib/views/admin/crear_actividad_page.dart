import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evento.dart';
import '../../models/actividad.dart';
import '../../models/zona.dart';
import '../../viewmodels/actividades_viewmodel.dart';
import '../../services/timezone.dart';

class CrearActividadPage extends StatefulWidget {
  final Evento evento;
  final Actividad? actividad; // null para crear, no null para editar

  const CrearActividadPage({
    super.key,
    required this.evento,
    this.actividad,
  });

  bool get esEdicion => actividad != null;

  @override
  State<CrearActividadPage> createState() => _CrearActividadPageState();
}

class _CrearActividadPageState extends State<CrearActividadPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _fechaController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicioSeleccionada;
  TimeOfDay? _horaFinSeleccionada;
  String? _zonaSeleccionada;

  bool _guardando = false;
  List<DateTime> _diasEvento = [];

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  void _inicializarDatos() {
    try {
      final viewModel = context.read<ActividadesViewModel>();
      _diasEvento = viewModel.generarDiasDelEvento(
        widget.evento.fechaInicio,
        widget.evento.fechaFin,
      );

      if (widget.esEdicion) {
        final actividad = widget.actividad!;
        _nombreController.text = actividad.nombre;
        _fechaSeleccionada = DateTime(
          actividad.fechaInicio.year,
          actividad.fechaInicio.month,
          actividad.fechaInicio.day,
        );
        _horaInicioSeleccionada = TimeOfDay.fromDateTime(actividad.fechaInicio);
        _horaFinSeleccionada = TimeOfDay.fromDateTime(actividad.fechaFin);
        _zonaSeleccionada = actividad.zona;
        
        _actualizarControladores();
      }
    } catch (e) {
      print('Error inicializando datos: $e');
      // En caso de error, usar fechas por defecto
      _diasEvento = [
        widget.evento.fechaInicio,
        widget.evento.fechaFin,
      ];
    }
  }

  void _actualizarControladores() {
    if (_fechaSeleccionada != null) {
      _fechaController.text = '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}';
    }
    if (_horaInicioSeleccionada != null) {
      final hora = _horaInicioSeleccionada!.hour.toString().padLeft(2, '0');
      final minuto = _horaInicioSeleccionada!.minute.toString().padLeft(2, '0');
      _horaInicioController.text = '$hora:$minuto';
    }
    if (_horaFinSeleccionada != null) {
      final hora = _horaFinSeleccionada!.hour.toString().padLeft(2, '0');
      final minuto = _horaFinSeleccionada!.minute.toString().padLeft(2, '0');
      _horaFinController.text = '$hora:$minuto';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _fechaController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar Actividad' : 'Nueva Actividad'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _guardarActividad,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccionEventoInfo(),
              const SizedBox(height: 24),
              _buildCampoNombre(),
              const SizedBox(height: 20),
              _buildCampoFecha(),
              const SizedBox(height: 20),
              _buildCamposHorario(),
              const SizedBox(height: 20),
              _buildCampoZona(),
              const SizedBox(height: 32),
              _buildBotonesAccion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionEventoInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Información del Evento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.evento.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Del ${_formatearFechaCorta(widget.evento.fechaInicio)} al ${_formatearFechaCorta(widget.evento.fechaFin)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoNombre() {
    return TextFormField(
      controller: _nombreController,
      decoration: const InputDecoration(
        labelText: 'Nombre de la actividad',
        hintText: 'Ej: Concurso de bandas de rock',
        prefixIcon: Icon(Icons.event_available),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor ingresa el nombre de la actividad';
        }
        if (value.trim().length < 3) {
          return 'El nombre debe tener al menos 3 caracteres';
        }
        return null;
      },
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildCampoFecha() {
    return TextFormField(
      controller: _fechaController,
      decoration: const InputDecoration(
        labelText: 'Fecha de la actividad',
        hintText: 'Selecciona una fecha',
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      readOnly: true,
      onTap: _seleccionarFecha,
      validator: (value) {
        if (_fechaSeleccionada == null) {
          return 'Por favor selecciona una fecha';
        }
        return null;
      },
    );
  }

  Widget _buildCamposHorario() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _horaInicioController,
            decoration: const InputDecoration(
              labelText: 'Hora de inicio',
              hintText: 'Ej: 09:00',
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () => _seleccionarHora(true),
            validator: (value) {
              if (_horaInicioSeleccionada == null) {
                return 'Selecciona hora de inicio';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _horaFinController,
            decoration: const InputDecoration(
              labelText: 'Hora de fin',
              hintText: 'Ej: 11:00',
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () => _seleccionarHora(false),
            validator: (value) {
              if (_horaFinSeleccionada == null) {
                return 'Selecciona hora de fin';
              }
              if (_horaInicioSeleccionada != null && _horaFinSeleccionada != null) {
                final inicio = _horaInicioSeleccionada!;
                final fin = _horaFinSeleccionada!;
                final inicioMinutos = inicio.hour * 60 + inicio.minute;
                final finMinutos = fin.hour * 60 + fin.minute;
                
                if (finMinutos <= inicioMinutos) {
                  return 'La hora de fin debe ser posterior a la de inicio';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCampoZona() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Zona del Parque Perú',
        hintText: 'Selecciona la zona',
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(),
      ),
      value: _zonaSeleccionada,
      items: ZonasParque.obtenerNombres().map((zona) {
        return DropdownMenuItem(
          value: zona,
          child: Text(zona),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _zonaSeleccionada = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona una zona';
        }
        return null;
      },
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _guardando ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _guardando ? null : _guardarActividad,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_guardando ? 'Guardando...' : 'Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    if (_diasEvento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar las fechas del evento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? _diasEvento.first,
      firstDate: _diasEvento.first,
      lastDate: _diasEvento.last,
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
        _actualizarControladores();
      });
    }
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final horaActual = esInicio ? _horaInicioSeleccionada : _horaFinSeleccionada;
    
    final hora = await showTimePicker(
      context: context,
      initialTime: horaActual ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: esInicio ? 'Hora de inicio' : 'Hora de fin',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        if (esInicio) {
          _horaInicioSeleccionada = hora;
        } else {
          _horaFinSeleccionada = hora;
        }
        _actualizarControladores();
      });
    }
  }

  Future<void> _guardarActividad() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      // Use TimezoneUtils instead of direct timezone calls
      final fechaInicio = TimezoneUtils.create(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaInicioSeleccionada!.hour,
        _horaInicioSeleccionada!.minute,
      );

      final fechaFin = TimezoneUtils.create(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaFinSeleccionada!.hour,
        _horaFinSeleccionada!.minute,
      );

      final viewModel = context.read<ActividadesViewModel>();

      // Verificar conflictos de horario
      final conflictos = await viewModel.verificarConflictosHorario(
        widget.evento.id,
        _zonaSeleccionada!,
        fechaInicio,
        fechaFin,
        actividadIdExcluir: widget.actividad?.id,
      );

      if (conflictos.isNotEmpty && mounted) {
        _mostrarDialogoConflictos(conflictos);
        return;
      }

      bool exito;

      if (widget.esEdicion) {
        final actividadActualizada = widget.actividad!.copyWith(
          nombre: _nombreController.text.trim(),
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          zona: _zonaSeleccionada!,
        );
        exito = await viewModel.actualizarActividad(actividadActualizada);
      } else {
        // Use TimezoneUtils for current time
        final nuevaActividad = Actividad(
          id: '',
          nombre: _nombreController.text.trim(),
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          zona: _zonaSeleccionada!,
          eventoId: widget.evento.id,
          fechaCreacion: TimezoneUtils.now(),
          fechaActualizacion: TimezoneUtils.now(),
        );
        exito = await viewModel.crearActividad(nuevaActividad);
      }

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.esEdicion 
                  ? 'Actividad actualizada correctamente'
                  : 'Actividad creada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al ${widget.esEdicion ? 'actualizar' : 'crear'} la actividad'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error inesperado. Inténtalo de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _mostrarDialogoConflictos(List<Actividad> conflictos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflicto de horarios'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ya existe una actividad en esta zona durante ese horario:'),
            const SizedBox(height: 12),
            ...conflictos.map((actividad) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actividad.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${actividad.horario} - ${actividad.zona}'),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _guardando = false;
              });
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _formatearFechaCorta(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}