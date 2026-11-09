import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/intercorrencia.dart';
import '../models/paciente.dart';
import '../models/pendencia.dart';
import '../models/sinais_vitais.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import 'medicacoes_checklist.dart';
import 'registrar_intercorrencia_screen.dart';
import 'registrar_sinais_screen.dart';
import '../widgets/marca.dart';

/// Tela 3 – Detalhe do paciente (GET /pacientes/:id) com abas.
class PacienteDetalheScreen extends ConsumerStatefulWidget {
  const PacienteDetalheScreen({super.key, required this.pacienteId, required this.setorId, this.abaInicial = 0});

  final String pacienteId;
  final String setorId;
  final int abaInicial;

  @override
  ConsumerState<PacienteDetalheScreen> createState() => _PacienteDetalheScreenState();
}

class _PacienteDetalheScreenState extends ConsumerState<PacienteDetalheScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this, initialIndex: widget.abaInicial)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _atualizar() => atualizarDadosDoSetor(ref, widget.setorId, pacienteId: widget.pacienteId);

  Future<void> _abrir(Widget tela) async {
    final salvou = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => tela));
    if (salvou == true) _atualizar();
  }

  Widget? _botao(PacienteDetalhe? p) {
    if (p == null) return null;
    return switch (_tabs.index) {
      0 => FloatingActionButton.extended(
        onPressed: () => _abrir(RegistrarSinaisScreen(paciente: p)),
        icon: const Icon(Icons.monitor_heart),
        label: const Text('Sinais vitais'),
      ),
      2 => FloatingActionButton.extended(
        onPressed: () => _abrir(RegistrarIntercorrenciaScreen(paciente: p)),
        icon: const Icon(Icons.report_outlined),
        label: const Text('Intercorrência'),
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = pacienteProvider(widget.pacienteId);
    final valor = ref.watch(provider);
    final p = valor.asData?.value;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FundoBarraClinica(),
        title: Text(p == null ? 'Paciente' : 'Leito ${p.leito}'),
        actions: [
          IconButton(tooltip: 'Atualizar', onPressed: () => ref.invalidate(provider), icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _botao(p),
      body: EstadoAsync<PacienteDetalhe>(
        valor: valor,
        aoTentarNovamente: () => ref.invalidate(provider),
        construtor: (p) => NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _Cabecalho(paciente: p)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarFixa(
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    const Tab(icon: Icon(Icons.monitor_heart_outlined), text: 'Sinais vitais'),
                    Tab(
                      icon: Badge(
                        isLabelVisible: p.medicacoesAtrasadas > 0,
                        label: Text('${p.medicacoesAtrasadas}'),
                        child: const Icon(Icons.medication_outlined),
                      ),
                      text: 'Medicações',
                    ),
                    const Tab(icon: Icon(Icons.report_outlined), text: 'Intercorrências'),
                    Tab(
                      icon: Badge(
                        isLabelVisible: p.pendenciasLista.any((x) => !x.concluida),
                        label: Text('${p.pendenciasLista.where((x) => !x.concluida).length}'),
                        child: const Icon(Icons.pending_actions_outlined),
                      ),
                      text: 'Pendências',
                    ),
                  ],
                ),
                Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _AbaSinais(paciente: p),
              MedicacoesChecklist(paciente: p, aoAlterar: _atualizar),
              _AbaIntercorrencias(paciente: p),
              _AbaPendencias(paciente: p, aoAlterar: _atualizar),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarFixa extends SliverPersistentHeaderDelegate {
  _TabBarFixa(this.tabBar, this.fundo);

  final TabBar tabBar;
  final Color fundo;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Material(color: fundo, elevation: overlapsContent ? 2 : 0, child: tabBar);

  @override
  bool shouldRebuild(_TabBarFixa old) => old.tabBar != tabBar || old.fundo != fundo;
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.paciente});

  final PacienteDetalhe paciente;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    final tema = Theme.of(context);
    final dias = DateTime.now().difference(p.dataInternacao).inDays;
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: CoresClinicas.risco(p.risco), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nome, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('${p.idade} ${p.idade == 1 ? 'ano' : 'anos'} · ${p.sexo} · internado(a) há $dias dia(s)'),
            const SizedBox(height: 8),
            Text(p.diagnostico, style: tema.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                EtiquetaRisco(p.risco),
                if (p.temAlergia)
                  EtiquetaAlergia(p.alergias)
                else
                  const Etiqueta(texto: 'Sem alergias conhecidas', cor: CoresClinicas.ok),
                for (final a in p.alertas) Etiqueta(texto: a, cor: CoresClinicas.medio, icone: Icons.monitor_heart),
              ],
            ),
            Theme(
              data: tema.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: const Text('Histórico, dieta e dispositivos'),
                children: [
                  _Linha(icone: Icons.history_edu, texto: p.historico),
                  _Linha(icone: Icons.restaurant, texto: 'Dieta: ${p.dieta.isEmpty ? '—' : p.dieta}'),
                  _Linha(
                    icone: Icons.cable,
                    texto: 'Dispositivos: ${p.dispositivos.isEmpty ? 'nenhum' : p.dispositivos.join(', ')}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(texto)),
      ],
    ),
  );
}

// ------------------------------- Abas -------------------------------

class _AbaSinais extends StatelessWidget {
  const _AbaSinais({required this.paciente});

  final PacienteDetalhe paciente;

  @override
  Widget build(BuildContext context) {
    if (paciente.sinaisVitais.isEmpty) {
      return const MensagemVazia(
        mensagem: 'Nenhum sinal vital registrado.\nToque em "Sinais vitais" para aferir.',
        icone: Icons.monitor_heart_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: paciente.sinaisVitais.length,
      itemBuilder: (_, i) => CardSinais(sv: paciente.sinaisVitais[i], destaque: i == 0),
    );
  }
}

class CardSinais extends StatelessWidget {
  const CardSinais({super.key, required this.sv, this.destaque = false});

  final SinaisVitais sv;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final alertas = sv.alertas;
    final tema = Theme.of(context);
    Widget valor(String rotulo, String v, {bool alerta = false}) => SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: tema.textTheme.labelSmall),
          Text(
            v,
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: alerta ? CoresClinicas.alto : null,
            ),
          ),
        ],
      ),
    );
    return Card(
      color: destaque ? tema.colorScheme.secondaryContainer.withValues(alpha: 0.5) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: tema.colorScheme.outline),
                const SizedBox(width: 4),
                Text('${dataHora(sv.registradoEm)} (${relativo(sv.registradoEm)})'),
                const Spacer(),
                if (destaque) const Etiqueta(texto: 'Mais recente', cor: Colors.blueGrey),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              runSpacing: 8,
              children: [
                valor('PA (mmHg)', '${sv.pas}/${sv.pad}', alerta: sv.pas >= 160 || sv.pas < 90),
                valor('FC (bpm)', '${sv.fc}', alerta: sv.fc > 120 || sv.fc < 50),
                valor('FR (irpm)', '${sv.fr}', alerta: sv.fr > 24),
                valor('Temp. (°C)', sv.temperatura.toStringAsFixed(1), alerta: sv.temperatura >= 37.8),
                valor('SatO2 (%)', '${sv.satO2}', alerta: sv.satO2 < 92),
                valor('Dor (0–10)', '${sv.dor}', alerta: sv.dor >= 7),
              ],
            ),
            if (alertas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final a in alertas) Etiqueta(texto: a, cor: CoresClinicas.alto, icone: Icons.warning_amber),
                ],
              ),
            ],
            if (sv.observacao.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Obs.: ${sv.observacao}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (sv.responsavel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Por ${sv.responsavel}', style: tema.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _AbaIntercorrencias extends StatelessWidget {
  const _AbaIntercorrencias({required this.paciente});

  final PacienteDetalhe paciente;

  @override
  Widget build(BuildContext context) {
    if (paciente.intercorrencias.isEmpty) {
      return const MensagemVazia(mensagem: 'Nenhuma intercorrência registrada.', icone: Icons.check_circle_outline);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: paciente.intercorrencias.length,
      itemBuilder: (_, i) {
        final it = paciente.intercorrencias[i];
        final cor = CoresClinicas.gravidade(it.gravidade);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.15),
              child: Icon(it.gravidade == Gravidade.grave ? Icons.priority_high : Icons.report_outlined, color: cor),
            ),
            title: Text(it.descricao),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${dataHora(it.horario)} · ${it.responsavel ?? ''}'),
            ),
            trailing: Etiqueta(texto: it.gravidade.rotulo, cor: cor),
          ),
        );
      },
    );
  }
}

class _AbaPendencias extends ConsumerWidget {
  const _AbaPendencias({required this.paciente, required this.aoAlterar});

  final PacienteDetalhe paciente;
  final VoidCallback aoAlterar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (paciente.pendenciasLista.isEmpty) {
      return const MensagemVazia(mensagem: 'Nenhum exame, procedimento ou retorno pendente.', icone: Icons.task_alt);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [for (final x in paciente.pendenciasLista) ItemPendencia(pendencia: x, aoAlterar: aoAlterar)],
    );
  }
}

/// Item de pendência com caixa para marcar como concluída (PATCH /pendencias/:id).
class ItemPendencia extends ConsumerStatefulWidget {
  const ItemPendencia({super.key, required this.pendencia, required this.aoAlterar, this.mostrarPaciente = false});

  final Pendencia pendencia;
  final VoidCallback aoAlterar;
  final bool mostrarPaciente;

  @override
  ConsumerState<ItemPendencia> createState() => _ItemPendenciaState();
}

class _ItemPendenciaState extends ConsumerState<ItemPendencia> {
  bool _salvando = false;

  Future<void> _alternar(bool concluir) async {
    setState(() => _salvando = true);
    try {
      await ref.read(apiProvider).concluirPendencia(widget.pendencia.id, concluida: concluir);
      widget.aoAlterar();
      if (mounted) avisar(context, concluir ? 'Pendência concluída' : 'Pendência reaberta');
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.pendencia;
    final vencida = !x.concluida && x.prazo.isBefore(DateTime.now());
    final icone = switch (x.tipo) {
      'exame' => Icons.biotech_outlined,
      'procedimento' => Icons.healing_outlined,
      _ => Icons.forum_outlined,
    };
    return Card(
      child: CheckboxListTile(
        value: x.concluida,
        onChanged: _salvando ? null : (v) => _alternar(v ?? false),
        secondary: _salvando
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icone, color: vencida ? CoresClinicas.atrasada : null),
        title: Text(
          widget.mostrarPaciente && x.paciente != null ? '${x.paciente!.leito} · ${x.descricao}' : x.descricao,
          style: x.concluida ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
        ),
        subtitle: Text(
          widget.mostrarPaciente && x.paciente != null
              ? '${x.paciente!.nome} · prazo ${dataHora(x.prazo)}${vencida ? ' (vencido)' : ''}'
              : '${x.tipoRotulo} · prazo ${dataHora(x.prazo)}${vencida ? ' (vencido)' : ''}',
          style: vencida ? const TextStyle(color: CoresClinicas.atrasada) : null,
        ),
      ),
    );
  }
}
