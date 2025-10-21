import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventoGratis {
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String lugar;
  final bool requiereInscripcion;

  EventoGratis({
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.lugar,
    this.requiereInscripcion = false,
  });

  /// Formatea la fecha a un string legible
  String get fechaFormateada => DateFormat('dd/MM/yyyy – HH:mm').format(fecha);

  /// Construye un widget detallado del evento
  Widget buildCard(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.event_available, color: Colors.blue, size: 40),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text('Fecha: $fechaFormateada'),
            Text('Lugar: $lugar'),
            Text('Entrada: Gratis'),
            Text('Requiere inscripción: ${requiereInscripcion ? "Sí" : "No"}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _mostrarDetalles(context);
          },
          child: const Text('Detalles'),
        ),
      ),
    );
  }

  void _mostrarDetalles(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción:\n$descripcion'),
            const SizedBox(height: 10),
            Text('Fecha: $fechaFormateada'),
            Text('Lugar: $lugar'),
            const Text('Entrada: Gratis'),
            Text('Requiere inscripción: ${requiereInscripcion ? "Sí" : "No"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (requiereInscripcion)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('¡Inscripción para "$titulo" realizada!')),
                );
              },
              child: const Text('Inscribirse'),
            ),
        ],
      ),
    );
  }
}
