import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventoPago {
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final double precio;
  final String lugar;
  final int cuposDisponibles;
  final bool requiereRegistro;

  EventoPago({
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.precio,
    required this.lugar,
    this.cuposDisponibles = 0,
    this.requiereRegistro = true,
  });

  /// Método para validar si aún hay cupos
  bool get hayCuposDisponibles => cuposDisponibles > 0;

  /// Formatea la fecha a un string legible
  String get fechaFormateada => DateFormat('dd/MM/yyyy – HH:mm').format(fecha);

  /// Formatea el precio con moneda
  String get precioFormateado => NumberFormat.simpleCurrency().format(precio);

  /// Construye un widget detallado del evento
  Widget buildCard(BuildContext context) {
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.attach_money, color: Colors.green, size: 40),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text('Fecha: $fechaFormateada'),
            Text('Lugar: $lugar'),
            Text('Precio: $precioFormateado'),
            Text('Cupos disponibles: $cuposDisponibles'),
            Text('Requiere registro: ${requiereRegistro ? "Sí" : "No"}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed:
              hayCuposDisponibles
                  ? () {
                    _mostrarDetalles(context);
                  }
                  : null,
          child: const Text('Detalles'),
        ),
      ),
    );
  }

  void _mostrarDetalles(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(titulo),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción:\n$descripcion'),
                const SizedBox(height: 10),
                Text('Fecha: $fechaFormateada'),
                Text('Lugar: $lugar'),
                Text('Precio: $precioFormateado'),
                Text('Cupos disponibles: $cuposDisponibles'),
                Text('Requiere registro: ${requiereRegistro ? "Sí" : "No"}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              if (hayCuposDisponibles)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('¡Registro para "$titulo" realizado!'),
                      ),
                    );
                  },
                  child: const Text('Registrar'),
                ),
            ],
          ),
    );
  }
}
