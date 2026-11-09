import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/intercorrencia.dart';
import '../models/paciente.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import '../widgets/marca.dart';

/// Tela 4b – Registro de intercorrência (POST /pacientes/:id/intercorrencias).
class RegistrarIntercorrenciaScreen extends ConsumerStatefulWidget {
  const RegistrarIntercorrenciaScreen({super.key, required this.paciente});

  final PacienteResumo paciente;

  @override
  ConsumerState<RegistrarIntercorrenciaScreen> createState() => _RegistrarIntercorrenciaScreenState();
}

class _RegistrarIntercorrenciaScreenState extends ConsumerState<RegistrarIntercorrenciaScreen> {
  final _form = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  Gravidade _gravidade = Gravidade.leve;
  DateTime _horario = DateTime.now();
  bool _salvando = false;

  /// Atalhos para reduzir digitação.
  static const _modelos = [
    'Queda do leito',
    'Pico febril',
    'Vômito',
    'Dessaturação',
    'Dor não controlada',
    'Agitação psicomotora',
    'Perda de acesso venoso',
    'Recusa de medicação',
  ];

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherHorario() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_horario));
    if (t == null) return;
    final agora = DateTime.now();
    var novo = DateTime(agora.year, agora.month, agora.day, t.hour, t.minute);
    // Um horário "no futuro" provavelmente se refere à noite anterior.
    if (novo.isAfter(agora)) novo = novo.subtract(const Duration(days: 1));
    setState(() => _horario = novo);
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await ref
          .read(apiProvider)
          .registrarIntercorrencia(
            widget.paciente.id,
            descricao: _descricao.text.trim(),
            gravidade: _gravidade,
            horario: _horario,
          );
      if (!mounted) return;
      avisar(context, 'Intercorrência registrada');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FundoBarraClinica(),
        title: Text('Intercorrência · ${widget.paciente.leito}'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.paciente.nome, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Atalhos', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _modelos)
                  ActionChip(
                    label: Text(m),
                    onPressed: () {
                      final atual = _descricao.text.trim();
                      _descricao.text = atual.isEmpty ? '$m: ' : '$atual. $m: ';
                      _descricao.selection = TextSelection.collapsed(offset: _descricao.text.length);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricao,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'O que aconteceu e qual conduta foi tomada?',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Descreva a intercorrência' : null,
            ),
            const SizedBox(height: 8),
            Text('Gravidade', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<Gravidade>(
              segments: [
                for (final g in Gravidade.values)
                  ButtonSegment(
                    value: g,
                    label: Text(g.rotulo),
                    icon: Icon(Icons.circle, size: 12, color: CoresClinicas.gravidade(g)),
                  ),
              ],
              selected: {_gravidade},
              onSelectionChanged: (s) => setState(() => _gravidade = s.first),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horário'),
              subtitle: Text(dataHora(_horario)),
              trailing: TextButton(onPressed: _escolherHorario, child: const Text('Alterar')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                style: _gravidade == Gravidade.grave
                    ? FilledButton.styleFrom(backgroundColor: CoresClinicas.alto)
                    : null,
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Registrar intercorrência'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
