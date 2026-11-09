import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medicacao.dart';
import '../models/paciente.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';

/// Tela 5 – Checklist de medicações por horário (PATCH /medicacoes/:id).
/// Atrasadas aparecem em vermelho e no topo; um toque marca como administrada.
class MedicacoesChecklist extends ConsumerStatefulWidget {
  const MedicacoesChecklist({super.key, required this.paciente, required this.aoAlterar});

  final PacienteDetalhe paciente;
  final VoidCallback aoAlterar;

  @override
  ConsumerState<MedicacoesChecklist> createState() => _MedicacoesChecklistState();
}

class _MedicacoesChecklistState extends ConsumerState<MedicacoesChecklist> {
  final Set<String> _salvando = {};

  Future<void> _administrar(Medicacao m) async {
    setState(() => _salvando.add(m.id));
    final api = ref.read(apiProvider);
    try {
      await api.administrar(m.id);
      widget.aoAlterar();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('${m.nome} das ${hora(m.horario)} registrada como administrada'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () async {
                try {
                  await api.desfazerAdministracao(m.id);
                  widget.aoAlterar();
                } catch (e) {
                  if (mounted) avisar(context, e.toString(), erro: true);
                }
              },
            ),
          ),
        );
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _salvando.remove(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = widget.paciente.medicacoes;
    if (meds.isEmpty) {
      return const MensagemVazia(mensagem: 'Nenhuma medicação prescrita para hoje.', icone: Icons.medication_outlined);
    }

    final atrasadas = meds.where((m) => m.atrasada).toList();
    final aFazer = meds.where((m) => !m.administrada && !m.atrasada).toList();
    final feitas = meds.where((m) => m.administrada).toList()..sort((a, b) => b.horario.compareTo(a.horario));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (widget.paciente.temAlergia)
          Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: EtiquetaAlergia(widget.paciente.alergias)),
        if (atrasadas.isNotEmpty) ...[
          TituloSecao('Atrasadas (${atrasadas.length})', icone: Icons.alarm, cor: CoresClinicas.atrasada),
          for (final m in atrasadas) _item(m),
        ],
        if (aFazer.isNotEmpty) ...[
          TituloSecao('Próximos horários (${aFazer.length})', icone: Icons.schedule),
          ..._porHorario(aFazer),
        ],
        if (feitas.isNotEmpty) ...[
          TituloSecao('Administradas (${feitas.length})', icone: Icons.check_circle_outline, cor: CoresClinicas.ok),
          for (final m in feitas) _item(m),
        ],
      ],
    );
  }

  /// Agrupa as doses futuras pelo mesmo horário (ex.: tudo das 14:00 junto).
  List<Widget> _porHorario(List<Medicacao> lista) {
    final grupos = <String, List<Medicacao>>{};
    for (final m in lista) {
      grupos.putIfAbsent(dataHora(m.horario), () => []).add(m);
    }
    return [
      for (final e in grupos.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
          child: Text(e.key, style: Theme.of(context).textTheme.labelLarge),
        ),
        for (final m in e.value) _item(m),
      ],
    ];
  }

  Widget _item(Medicacao m) {
    final salvando = _salvando.contains(m.id);
    final cor = m.atrasada ? CoresClinicas.atrasada : (m.administrada ? CoresClinicas.ok : null);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: m.atrasada
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CoresClinicas.atrasada, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(
                    hora(m.horario),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cor),
                  ),
                  if (m.atrasada)
                    Text(relativo(m.horario), style: const TextStyle(fontSize: 11, color: CoresClinicas.atrasada)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${m.dose} · ${m.via}'),
                  if (m.administrada && m.administradaEm != null)
                    Text(
                      'Administrada às ${hora(m.administradaEm!)} por ${m.responsavel ?? '—'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: CoresClinicas.ok),
                    ),
                ],
              ),
            ),
            if (m.administrada)
              const Icon(Icons.check_circle, color: CoresClinicas.ok, size: 32)
            else
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: m.atrasada ? FilledButton.styleFrom(backgroundColor: CoresClinicas.atrasada) : null,
                  onPressed: salvando ? null : () => _administrar(m),
                  icon: salvando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Administrar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
