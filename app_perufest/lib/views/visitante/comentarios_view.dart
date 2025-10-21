import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../viewmodels/comentarios_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/comentario.dart';
import 'opiniones_todas_page.dart';

class ComentariosView extends StatefulWidget {
  final String standId;
  final String standNombre;

  const ComentariosView({
    super.key,
    required this.standId,
    required this.standNombre,
  });

  @override
  State<ComentariosView> createState() => _ComentariosViewState();
}

class _ComentariosViewState extends State<ComentariosView> {
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  int _estrellas = 5;
  bool _enviando = false;

  late ComentariosViewModel _vm;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ComentariosViewModel>();
    _listener = () {
      if (mounted) setState(() {});
    };
    _vm.addListener(_listener);
    _vm.cargarComentariosPorStand(widget.standId);
  }

  @override
  void dispose() {
    _vm.removeListener(_listener);
    _textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<ComentariosViewModel>();

    final publicos =
        vm.comentarios
            .where((c) => c.publico && c.standId == widget.standId)
            .toList();
    publicos.sort((a, b) => b.utilSi.compareTo(a.utilSi));
    final top3 = publicos.length <= 3 ? publicos : publicos.sublist(0, 3);

    return Scaffold(
      appBar: AppBar(title: Text('Valorar: ${widget.standNombre}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildResumen(vm),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildForm(auth, vm),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Opiniones públicas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              if (vm.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (publicos.isEmpty)
                const Center(
                  child: Text('Aún no hay comentarios. Sé el primero.'),
                )
              else
                ...List.generate(
                  top3.length,
                  (index) => _buildComentarioCard(top3[index], vm),
                ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => OpinionesTodasPage(standId: widget.standId),
                      ),
                    );
                  },
                  child: const Text('Ver todas las opiniones'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumen(ComentariosViewModel vm) {
    final comentariosStand =
        vm.comentarios.where((c) => c.standId == widget.standId).toList();
    final total = comentariosStand.length;
    final counts = List<int>.filled(6, 0);
    for (final c in comentariosStand) {
      if (c.estrellas >= 1 && c.estrellas <= 5) counts[c.estrellas]++;
    }
    final sum = comentariosStand.fold<int>(0, (s, c) => s + c.estrellas);
    final average = total == 0 ? 0.0 : sum / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < average.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('$total calificaciones'),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  final count = counts[star];
                  final fraction = total == 0 ? 0.0 : count / total;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text('$star'),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.green,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthViewModel auth, ComentariosViewModel vm) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TU OPINIÓN',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                onPressed: () => setState(() => _estrellas = idx),
                icon: Icon(
                  idx <= _estrellas ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textoController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe tu comentario (opcional)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if ((v ?? '').length > 1000) return 'Comentario demasiado largo';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _enviando ? null : () => _enviarComentario(auth, vm),
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar valoración'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComentarioCard(Comentario c, ComentariosViewModel vm) {
    final fecha = tz.TZDateTime.from(c.fecha.toUtc(), tz.local);
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';
    final voto = vm.getVotoUsuario(c.id, userId); // 'si', 'no' o null
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  c.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < c.estrellas ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (c.texto.isNotEmpty) Text(c.texto),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy - hh:mm a', 'es').format(fecha),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text('Esta opinión les resultó útil a ${c.utilSi} personas'),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('¿Te resultó útil esta opinión?'),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Si'),
                      if (voto == 'si') ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, color: Colors.green, size: 18),
                      ],
                    ],
                  ),
                  selected: voto == 'si',
                  selectedColor: Colors.green.shade100,
                  onSelected: (selected) async {
                    if (selected && voto != 'si') {
                      final ok = await vm.marcarVotoUnico(
                        c.id,
                        userId,
                        'si',
                        voto,
                      );
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Gracias por tu opinión!'),
                          ),
                        );
                        vm.cargarComentariosPorStand(widget.standId);
                      }
                    }
                  },
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No'),
                      if (voto == 'no') ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, color: Colors.red, size: 18),
                      ],
                    ],
                  ),
                  selected: voto == 'no',
                  selectedColor: Colors.red.shade100,
                  onSelected: (selected) async {
                    if (selected && voto != 'no') {
                      final ok = await vm.marcarVotoUnico(
                        c.id,
                        userId,
                        'no',
                        voto,
                      );
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Gracias por tu opinión!'),
                          ),
                        );
                        vm.cargarComentariosPorStand(widget.standId);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarComentario(
    AuthViewModel auth,
    ComentariosViewModel vm,
  ) async {
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comentar')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    final comentario = Comentario(
      id: '',
      standId: widget.standId,
      userId: auth.currentUser!.id,
      userName: auth.currentUser!.nombre,
      texto: _textoController.text.trim(),
      estrellas: _estrellas,
      fecha: DateTime.now().toUtc(),
      publico: true,
    );

    final ok = await vm.publicarComentario(comentario);
    setState(() => _enviando = false);
    if (ok) {
      _textoController.clear();
      setState(() => _estrellas = 5);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Valoración enviada')));
      vm.cargarComentariosPorStand(widget.standId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar valoración')),
      );
    }
  }
}
