import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movimentacao.dart';
import '../models/paciente.dart';
import '../providers/providers.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import '../widgets/marca.dart';

/// Saída do paciente: alta hospitalar, transferência ou óbito (POST /pacientes/:id/alta).
class DarAltaScreen extends ConsumerStatefulWidget {
  const DarAltaScreen({super.key, required this.paciente});

  final PacienteDetalhe paciente;

  @override
  ConsumerState<DarAltaScreen> createState() => _DarAltaScreenState();
}

class _DarAltaScreenState extends ConsumerState<DarAltaScreen> {
  final _form = GlobalKey<FormState>();
  final _destino = TextEditingController();
  final _observacao = TextEditingController();
  TipoSaida _tipo = TipoSaida.alta;
  bool _salvando = false;

  /// Checklist de saída segura – os itens marcados vão para a observação.
  static const _checklist = {
    TipoSaida.alta: [
      'Orientações de alta entregues ao paciente/família',
      'Receitas e relatório de alta entregues',
      'Acesso venoso e dispositivos retirados',
      'Pertences devolvidos',
    ],
    TipoSaida.transferencia: [
      'Setor de destino avisado (contato feito)',
      'Prontuário e exames enviados',
      'Paciente estável para o transporte',
    ],
    TipoSaida.obito: [
      'Médico constatou e registrou o óbito',
      'Família comunicada',
      'Serviço social / necrotério acionado',
    ],
  };
  final Set<String> _marcados = {};

  @override
  void dispose() {
    _destino.dispose();
    _observacao.dispose();
    super.dispose();
  }

  String get _rotuloDestino => switch (_tipo) {
    TipoSaida.alta => 'Destino (opcional)',
    TipoSaida.transferencia => 'Para onde? (ex.: UTI adulto, Hospital X)',
    TipoSaida.obito => 'Horário / médico que constatou (opcional)',
  };

  Future<void> _confirmar() async {
    if (!_form.currentState!.validate()) return;
    final p = widget.paciente;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(_tipo == TipoSaida.obito ? Icons.sentiment_very_dissatisfied_outlined : Icons.logout),
        title: Text('Confirmar ${_tipo.rotulo.toLowerCase()}?'),
        content: Text(
          '${p.nome} sairá da lista do setor e o leito ${p.leito} ficará livre. '
          'Pendências e medicações em aberto deste paciente deixam de aparecer.\n\nEssa ação não pode ser desfeita pelo app.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar saída')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _salvando = true);
    final itens = _checklist[_tipo]!.where(_marcados.contains).toList();
    final obs = [
      if (_observacao.text.trim().isNotEmpty) _observacao.text.trim(),
      if (itens.isNotEmpty) 'Checklist: ${itens.join('; ')}.',
    ].join('\n');
    try {
      await ref.read(apiProvider).darAlta(p.id, tipo: _tipo, destino: _destino.text.trim(), observacao: obs);
      if (!mounted) return;
      atualizarDadosDoSetor(ref, p.setorId, pacienteId: p.id);
      avisar(context, '${_tipo.rotulo} registrada. Leito ${p.leito} liberado.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paciente;
    final tema = Theme.of(context);
    final abertas = p.pendenciasLista.where((x) => !x.concluida).length + p.medicacoesAtrasadas;

    return Scaffold(
      appBar: AppBar(flexibleSpace: const FundoBarraClinica(), title: Text('Saída · ${p.leito}')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(p.nome, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('${p.idade} anos · ${p.diagnostico}'),
            if (abertas > 0) ...[
              const SizedBox(height: 12),
              Card(
                color: CoresClinicas.medio.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.pending_actions, color: CoresClinicas.medio),
                  title: Text('$abertas pendência(s) em aberto'),
                  subtitle: const Text('Confira se algo precisa ser resolvido ou repassado antes da saída.'),
                ),
              ),
            ],
            const TituloSecao('Tipo de saída', icone: Icons.logout),
            SegmentedButton<TipoSaida>(
              segments: [
                for (final t in TipoSaida.values)
                  ButtonSegment(
                    value: t,
                    label: Text(t.rotulo, textAlign: TextAlign.center),
                  ),
              ],
              selected: {_tipo},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() {
                _tipo = s.first;
                _marcados.clear();
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destino,
              maxLength: 200,
              decoration: InputDecoration(labelText: _rotuloDestino),
              validator: (v) =>
                  _tipo == TipoSaida.transferencia && (v == null || v.trim().isEmpty) ? 'Informe o destino' : null,
            ),
            const TituloSecao('Checklist de saída segura', icone: Icons.checklist),
            for (final item in _checklist[_tipo]!)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _marcados.contains(item),
                title: Text(item),
                onChanged: (v) => setState(() => v == true ? _marcados.add(item) : _marcados.remove(item)),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _observacao,
              maxLines: 3,
              maxLength: 800,
              decoration: const InputDecoration(labelText: 'Observação (opcional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                style: _tipo == TipoSaida.obito
                    ? FilledButton.styleFrom(backgroundColor: Colors.blueGrey.shade700)
                    : null,
                onPressed: _salvando ? null : _confirmar,
                icon: _salvando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.how_to_reg_outlined),
                label: Text('Registrar ${_tipo.rotulo.toLowerCase()}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
