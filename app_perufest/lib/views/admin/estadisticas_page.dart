import 'package:flutter/material.dart';

class EstadisticasPage extends StatelessWidget {
  const EstadisticasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64),
          SizedBox(height: 16),
          Text(
            'Estadísticas del Sistema',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Aquí podrás ver estadísticas y reportes'),
        ],
      ),
    );
  }
}
