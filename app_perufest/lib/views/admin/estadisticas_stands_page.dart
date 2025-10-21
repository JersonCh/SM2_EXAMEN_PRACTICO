import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstadisticasStandsPage extends StatefulWidget {
  const EstadisticasStandsPage({super.key});

  @override
  State<EstadisticasStandsPage> createState() => _EstadisticasStandsPageState();
}

class _EstadisticasStandsPageState extends State<EstadisticasStandsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas por Stand'),
        backgroundColor: const Color(0xFF8B1B1B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('stands').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final stands = snapshot.data!.docs;
          if (stands.isEmpty)
            return const Center(child: Text('No hay stands registrados'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: stands.length,
            itemBuilder: (context, index) {
              final s = stands[index];
              final standId = s.id;
              final standNombre =
                  (s.data() as Map<String, dynamic>)['nombre'] ??
                  (s.data() as Map<String, dynamic>)['name'] ??
                  standId;

              return FutureBuilder<QuerySnapshot>(
                future:
                    _firestore
                        .collection('comentarios')
                        .where('standId', isEqualTo: standId)
                        .where('publico', isEqualTo: true)
                        .get(),
                builder: (context, qsnap) {
                  if (!qsnap.hasData)
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );

                  final comments = qsnap.data!.docs;
                  final total = comments.length;
                  final counts = List<int>.filled(6, 0);
                  var sum = 0;
                  for (final d in comments) {
                    final data = d.data() as Map<String, dynamic>;
                    final est =
                        (data['estrellas'] ?? data['rating'] ?? 0) as int;
                    if (est >= 1 && est <= 5) {
                      counts[est]++;
                      sum += est;
                    }
                  }
                  final average = total == 0 ? 0.0 : sum / total;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  standNombre.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                total == 0
                                    ? 'Sin calificaciones'
                                    : '${average.toStringAsFixed(1)} ★ - $total',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: List.generate(5, (i) {
                              final star = 5 - i;
                              final count = counts[star];
                              final fraction = total == 0 ? 0.0 : count / total;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Text('$star'),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: fraction,
                                        backgroundColor: Colors.grey.shade200,
                                        color: const Color(0xFF0F9D58),
                                        minHeight: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(width: 28, child: Text('$count')),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
