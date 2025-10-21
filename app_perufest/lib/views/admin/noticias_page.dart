import 'package:flutter/material.dart';

class NoticiasPage extends StatelessWidget {
  const NoticiasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 64),
          SizedBox(height: 16),
          Text(
            'Gestión de Noticias',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Aquí podrás crear y administrar noticias'),
        ],
      ),
    );
  }
}