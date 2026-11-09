import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medicacao.dart';
import '../models/pendencia.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import 'paciente_detalhe_screen.dart';

/// Tela 6 – Pendências do setor (GET /pendencias?setor=).
class PendenciasScreen extends ConsumerWidget {
  const PendenciasScreen({super.key, required this.setorId});

  final String setorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = pendenciasProvider(setorId);
    void atualizar() => atualizarDadosDoSetor(ref, setorId);

    return EstadoAsync<PendenciasSetor>(
      valor: ref.watch(provider),
      aoTentarNovamente: () => ref.invalidate(provider),
      estaVazio: (p) => p.vazio,
      mensagemVazio: 'Tudo em dia! Nenhuma medicação atrasada ou pendência aberta no setor.',
      iconeVazio: Icons.task_alt,
      construtor: (p) => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _secao(context, 'Medicações atrasadas', p.medicacoesAtrasadas.length, Icons.alarm, CoresClinicas.atrasada, [
              for (final m in p.medicacoesAtrasadas) _MedicacaoAtrasada(med: m, setorId: setorId, aoAlterar: atualizar),
            ]),
            _secao(context, 'Exames', p.exames.length, Icons.biotech_outlined, null, _pendencias(p.exames, atualizar)),
            _secao(
              context,
              'Procedimentos',
              p.procedimentos.length,
              Icons.healing_outlined,
              null,
              _pendencias(p.procedimentos, atualizar),
            ),
            _secao(
              context,
              'Retornos e pareceres',
              p.retornos.length,
              Icons.forum_outlined,
              null,
              _pendencias(p.retornos, atualizar),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _pendencias(List<Pendencia> lista, VoidCallback atualizar) => [
    for (final x in lista)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ItemPendencia(pendencia: x, aoAlterar: atualizar, mostrarPaciente: true),
      ),
  ];

  Widget _secao(BuildContext context, String titulo, int qtd, IconData icone, Color? cor, List<Widget> itens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSecao(
          titulo,
          icone: icone,
          cor: cor,
          trailing: Contador(valor: qtd, cor: qtd == 0 ? CoresClinicas.ok : (cor ?? CoresClinicas.medio)),
        ),
        if (itens.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Text('Nenhuma.'))
        else
          ...itens,
      ],
    );
  }
}

class _MedicacaoAtrasada extends ConsumerStatefulWidget {
  const _MedicacaoAtrasada({required this.med, required this.setorId, required this.aoAlterar});

  final Medicacao med;
  final String setorId;
  final VoidCallback aoAlterar;

  @override
  ConsumerState<_MedicacaoAtrasada> createState() => _MedicacaoAtrasadaState();
}

class _MedicacaoAtrasadaState extends ConsumerState<_MedicacaoAtrasada> {
  bool _salvando = false;

  Future<void> _administrar() async {
    setState(() => _salvando = true);
    try {
      await ref.read(apiProvider).administrar(widget.med.id);
      widget.aoAlterar();
      if (mounted) avisar(context, '${widget.med.nome} registrada como administrada');
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.med;
    final p = m.paciente;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CoresClinicas.atrasada),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: p == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PacienteDetalheScreen(pacienteId: p.id, setorId: widget.setorId, abaInicial: 1),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    hora(m.horario),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CoresClinicas.atrasada),
                  ),
                  Text(relativo(m.horario), style: const TextStyle(fontSize: 11, color: CoresClinicas.atrasada)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.descricao, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (p != null) Text('${p.leito} · ${p.nome}'),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Administrar',
                style: IconButton.styleFrom(backgroundColor: CoresClinicas.atrasada, minimumSize: const Size(48, 48)),
                onPressed: _salvando ? null : _administrar,
                icon: _salvando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
