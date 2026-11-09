import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plantao.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import '../widgets/marca.dart';

/// Resumo SBAR de um plantão (GET /plantoes/:id) + "Li e assumo o plantão".
class ResumoPlantaoScreen extends ConsumerStatefulWidget {
  const ResumoPlantaoScreen({super.key, required this.plantaoId});

  final String plantaoId;

  @override
  ConsumerState<ResumoPlantaoScreen> createState() => _ResumoPlantaoScreenState();
}

class _ResumoPlantaoScreenState extends ConsumerState<ResumoPlantaoScreen> {
  bool _soAtencao = false;
  bool _confirmando = false;

  Future<void> _confirmar(Plantao p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.how_to_reg),
        title: const Text('Assumir o plantão?'),
        content: Text(
          'Ao confirmar, fica registrado que você leu o resumo dos ${p.totais.pacientes} pacientes '
          'passados por ${p.responsavel.nome} e assume o cuidado a partir de agora.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Li e assumo')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _confirmando = true);
    try {
      await ref.read(apiProvider).confirmarLeitura(p.id);
      ref.invalidate(plantaoProvider(p.id));
      ref.invalidate(historicoProvider(p.setorId));
      if (mounted) avisar(context, 'Plantão assumido. Bom trabalho!');
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  void _copiar(Plantao p) {
    final texto = StringBuffer('Passagem de plantão – ${p.setorNome}\n')
      ..writeln('${dataHora(p.inicio)} até ${dataHora(p.fim)} · ${p.responsavel.nome}')
      ..writeln(p.observacoes.isEmpty ? '' : 'Observações: ${p.observacoes}\n');
    for (final s in p.resumo) {
      texto.writeln('${s.texto}\n');
    }
    Clipboard.setData(ClipboardData(text: texto.toString()));
    avisar(context, 'Resumo copiado');
  }

  @override
  Widget build(BuildContext context) {
    final provider = plantaoProvider(widget.plantaoId);
    final valor = ref.watch(provider);
    final usuario = ref.watch(sessaoProvider).usuario;
    final p = valor.asData?.value;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FundoBarraClinica(),
        title: const Text('Resumo SBAR'),
        actions: [
          if (p != null)
            IconButton(tooltip: 'Copiar resumo', onPressed: () => _copiar(p), icon: const Icon(Icons.copy_all)),
        ],
      ),
      body: EstadoAsync<Plantao>(
        valor: valor,
        aoTentarNovamente: () => ref.invalidate(provider),
        construtor: (p) {
          final lista = _soAtencao ? p.resumo.where((s) => s.precisaAtencao).toList() : p.resumo;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _Cabecalho(plantao: p),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('${lista.length} paciente(s)', style: Theme.of(context).textTheme.titleSmall)),
                  FilterChip(
                    label: const Text('Só quem precisa de atenção'),
                    selected: _soAtencao,
                    onSelected: (v) => setState(() => _soAtencao = v),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (lista.isEmpty)
                const MensagemVazia(mensagem: 'Nenhum paciente com alerta.', icone: Icons.check_circle_outline)
              else
                for (final s in lista) CardSbar(sbar: s),
            ],
          );
        },
      ),
      bottomNavigationBar: p == null
          ? null
          : _Rodape(
              plantao: p,
              ehResponsavel: p.responsavel.id == usuario?.id,
              confirmando: _confirmando,
              aoConfirmar: () => _confirmar(p),
            ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.plantao});

  final Plantao plantao;

  @override
  Widget build(BuildContext context) {
    final p = plantao;
    final tema = Theme.of(context);
    Widget numero(int v, String rotulo, Color cor) => Expanded(
      child: Column(
        children: [
          Text(
            '$v',
            style: tema.textTheme.headlineSmall?.copyWith(color: cor, fontWeight: FontWeight.bold),
          ),
          Text(rotulo, textAlign: TextAlign.center, style: tema.textTheme.bodySmall),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.setorNome, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('Turno: ${dataHora(p.inicio)} até ${dataHora(p.fim)}'),
            Text('Passado por: ${p.responsavel.nome} · ${p.responsavel.cargo}'),
            if (p.observacoes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Observações: ${p.observacoes}'),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                numero(p.totais.pacientes, 'pacientes', tema.colorScheme.primary),
                numero(
                  p.totais.medicacoesAtrasadas,
                  'med.\natrasadas',
                  p.totais.medicacoesAtrasadas > 0 ? CoresClinicas.atrasada : CoresClinicas.ok,
                ),
                numero(
                  p.totais.pendencias,
                  'pendências',
                  p.totais.pendencias > 0 ? CoresClinicas.medio : CoresClinicas.ok,
                ),
                numero(
                  p.totais.comAlerta,
                  'com alerta',
                  p.totais.comAlerta > 0 ? CoresClinicas.alto : CoresClinicas.ok,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card SBAR de um paciente.
class CardSbar extends StatelessWidget {
  const CardSbar({super.key, required this.sbar});

  final SbarPaciente sbar;

  @override
  Widget build(BuildContext context) {
    final s = sbar;
    final cor = CoresClinicas.risco(s.risco);
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: tema.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: s.precisaAtencao,
          leading: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8)),
            child: Text(
              s.leito.split('-').last,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (s.alergias.isNotEmpty) EtiquetaAlergia(s.alergias, compacta: true),
              if (s.medicacoesAtrasadas > 0)
                Etiqueta(texto: '${s.medicacoesAtrasadas} atrasada(s)', cor: CoresClinicas.atrasada),
              if (s.alertas.isNotEmpty) Etiqueta(texto: '${s.alertas.length} alerta(s)', cor: CoresClinicas.medio),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _Bloco(letra: 'S', titulo: 'Situação', texto: s.situacao, cor: const Color(0xFF1565C0)),
            _Bloco(letra: 'B', titulo: 'Breve histórico', texto: s.breveHistorico, cor: const Color(0xFF6A1B9A)),
            _Bloco(letra: 'A', titulo: 'Avaliação', texto: s.avaliacao, cor: const Color(0xFFEF6C00)),
            _Bloco(letra: 'R', titulo: 'Recomendação', texto: s.recomendacao, cor: const Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.letra, required this.titulo, required this.texto, required this.cor});

  final String letra;
  final String titulo;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: cor,
          child: Text(
            letra,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(color: cor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(texto),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.plantao,
    required this.ehResponsavel,
    required this.confirmando,
    required this.aoConfirmar,
  });

  final Plantao plantao;
  final bool ehResponsavel;
  final bool confirmando;
  final VoidCallback aoConfirmar;

  @override
  Widget build(BuildContext context) {
    final c = plantao.confirmacao;
    final Widget conteudo;
    if (c != null) {
      conteudo = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CoresClinicas.ok.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CoresClinicas.ok),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: CoresClinicas.ok),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lido e assumido por ${c.profissional.nome} (${c.profissional.cargo}) em ${dataHora(c.confirmadoEm)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } else if (ehResponsavel) {
      conteudo = const ListTile(
        leading: Icon(Icons.hourglass_top, color: CoresClinicas.medio),
        title: Text('Aguardando confirmação de quem assume'),
        subtitle: Text('O próximo profissional deve abrir este resumo no app dele e confirmar a leitura.'),
      );
    } else {
      conteudo = SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: confirmando ? null : aoConfirmar,
          icon: confirmando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.how_to_reg),
          label: const Text('Li e assumo o plantão'),
        ),
      );
    }
    return SafeArea(
      child: Material(
        elevation: 8,
        child: Padding(padding: const EdgeInsets.all(12), child: conteudo),
      ),
    );
  }
}
