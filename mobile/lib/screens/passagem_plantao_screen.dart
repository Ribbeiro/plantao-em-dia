import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plantao.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import 'resumo_plantao_screen.dart';

/// Tela 7 – Passagem de plantão.
/// "Encerrar meu turno" (POST /plantoes) gera o SBAR; quem assume abre o resumo
/// e confirma a leitura (POST /plantoes/:id/confirmar).
class PassagemPlantaoScreen extends ConsumerStatefulWidget {
  const PassagemPlantaoScreen({super.key, required this.setorId});

  final String setorId;

  @override
  ConsumerState<PassagemPlantaoScreen> createState() => _PassagemPlantaoScreenState();
}

class _PassagemPlantaoScreenState extends ConsumerState<PassagemPlantaoScreen> {
  bool _encerrando = false;

  Future<void> _encerrar() async {
    final obs = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.assignment_turned_in_outlined),
        title: const Text('Encerrar meu turno?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O app vai gerar o resumo SBAR de todos os pacientes do setor com os registros do seu turno.'),
            const SizedBox(height: 16),
            TextField(
              controller: obs,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Observações gerais (opcional)',
                hintText: 'ex.: falta de material, leito 05 aguardando vaga na UTI',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Encerrar e gerar SBAR')),
        ],
      ),
    );
    final texto = obs.text.trim();
    obs.dispose();
    if (confirmar != true || !mounted) return;

    setState(() => _encerrando = true);
    try {
      final plantao = await ref.read(apiProvider).encerrarTurno(widget.setorId, observacoes: texto);
      ref.invalidate(historicoProvider(widget.setorId));
      if (!mounted) return;
      avisar(context, 'Turno encerrado. Resumo gerado para ${plantao.totais.pacientes} pacientes.');
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResumoPlantaoScreen(plantaoId: plantao.id)));
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _encerrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = historicoProvider(widget.setorId);
    final usuarioId = ref.watch(sessaoProvider).usuario?.id;
    final historico = ref.watch(provider);
    final tema = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: tema.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.logout_rounded, color: tema.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Fim do turno',
                        style: tema.textTheme.titleLarge?.copyWith(color: tema.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revise as pendências e encerre seu turno. Quem assume recebe um resumo padronizado '
                    '(Situação, Breve histórico, Avaliação e Recomendação) e confirma a leitura.',
                    style: TextStyle(color: tema.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _encerrando ? null : _encerrar,
                      icon: _encerrando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.assignment_turned_in),
                      label: const Text('Encerrar meu turno'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          historico.when(
            skipLoadingOnRefresh: true,
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Carregando()),
            error: (e, _) => SizedBox(
              height: 320,
              child: MensagemErro(erro: e, aoTentarNovamente: () => ref.invalidate(provider)),
            ),
            data: (lista) {
              final aguardando = lista.where((p) => !p.confirmado && p.responsavel.id != usuarioId).toList();
              final meus = lista.where((p) => !p.confirmado && p.responsavel.id == usuarioId).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TituloSecao(
                    'Para você assumir',
                    icone: Icons.how_to_reg_outlined,
                    trailing: Contador(
                      valor: aguardando.length,
                      cor: aguardando.isEmpty ? CoresClinicas.ok : CoresClinicas.medio,
                    ),
                  ),
                  if (aguardando.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('Nenhum plantão aguardando confirmação de leitura.'),
                    )
                  else
                    for (final p in aguardando) CardPlantao(plantao: p, destaque: true),
                  if (meus.isNotEmpty) ...[
                    TituloSecao('Encerrados por você (aguardando quem assume)', icone: Icons.hourglass_top),
                    for (final p in meus) CardPlantao(plantao: p),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Card usado na passagem de plantão e no histórico.
class CardPlantao extends StatelessWidget {
  const CardPlantao({super.key, required this.plantao, this.destaque = false});

  final Plantao plantao;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final p = plantao;
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: destaque
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CoresClinicas.medio, width: 1.5),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResumoPlantaoScreen(plantaoId: p.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${hora(p.inicio)} – ${hora(p.fim)} · ${dataHora(p.fim).split(' ').first}',
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  p.confirmado
                      ? const Etiqueta(texto: 'Assumido', cor: CoresClinicas.ok, icone: Icons.verified)
                      : const Etiqueta(
                          texto: 'Aguardando leitura',
                          cor: CoresClinicas.medio,
                          icone: Icons.hourglass_top,
                        ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Passado por ${p.responsavel.nome} (${p.responsavel.cargo})'),
              if (p.confirmacao != null)
                Text(
                  'Assumido por ${p.confirmacao!.profissional.nome} às ${hora(p.confirmacao!.confirmadoEm)}',
                  style: const TextStyle(color: CoresClinicas.ok),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Etiqueta(texto: '${p.totais.pacientes} pacientes', cor: tema.colorScheme.primary),
                  if (p.totais.medicacoesAtrasadas > 0)
                    Etiqueta(texto: '${p.totais.medicacoesAtrasadas} med. atrasadas', cor: CoresClinicas.atrasada),
                  if (p.totais.pendencias > 0)
                    Etiqueta(texto: '${p.totais.pendencias} pendências', cor: CoresClinicas.medio),
                  if (p.totais.comAlerta > 0)
                    Etiqueta(texto: '${p.totais.comAlerta} com alerta', cor: CoresClinicas.alto),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
