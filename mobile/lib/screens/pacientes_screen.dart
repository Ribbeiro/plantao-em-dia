import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paciente.dart';
import '../providers/providers.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import 'paciente_detalhe_screen.dart';

enum _Filtro { todos, riscoAlto, comPendencias, alergia }

/// Tela 2 – Pacientes do setor (GET /setores/:id/pacientes).
class PacientesScreen extends ConsumerStatefulWidget {
  const PacientesScreen({super.key, required this.setorId});

  final String setorId;

  @override
  ConsumerState<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends ConsumerState<PacientesScreen> {
  _Filtro _filtro = _Filtro.todos;

  List<PacienteResumo> _filtrar(List<PacienteResumo> lista) => switch (_filtro) {
    _Filtro.todos => lista,
    _Filtro.riscoAlto => lista.where((p) => p.risco == Risco.alto).toList(),
    _Filtro.comPendencias => lista.where((p) => p.pendencias > 0).toList(),
    _Filtro.alergia => lista.where((p) => p.temAlergia).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final provider = pacientesProvider(widget.setorId);
    final pacientes = ref.watch(provider);

    return EstadoAsync<List<PacienteResumo>>(
      valor: pacientes,
      aoTentarNovamente: () => ref.invalidate(provider),
      estaVazio: (l) => l.isEmpty,
      mensagemVazio: 'Nenhum paciente internado neste setor.',
      iconeVazio: Icons.bed_outlined,
      construtor: (lista) {
        final filtrados = _filtrar(lista);
        return RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Resumo(lista: lista)),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final (f, rotulo) in [
                        (_Filtro.todos, 'Todos (${lista.length})'),
                        (_Filtro.riscoAlto, 'Risco alto'),
                        (_Filtro.comPendencias, 'Com pendências'),
                        (_Filtro.alergia, 'Alergia'),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(rotulo),
                            selected: _filtro == f,
                            onSelected: (_) => setState(() => _filtro = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (filtrados.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: MensagemVazia(mensagem: 'Nenhum paciente neste filtro.', icone: Icons.filter_alt_off),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  sliver: SliverList.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) => CardPaciente(paciente: filtrados[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.lista});

  final List<PacienteResumo> lista;

  @override
  Widget build(BuildContext context) {
    final atrasadas = lista.fold<int>(0, (t, p) => t + p.medicacoesAtrasadas);
    final alto = lista.where((p) => p.risco == Risco.alto).length;
    final alertas = lista.where((p) => p.alertas.isNotEmpty).length;
    Widget item(String valor, String rotulo, Color cor) => Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: cor, fontWeight: FontWeight.bold),
          ),
          Text(rotulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            item('${lista.length}', 'pacientes', Theme.of(context).colorScheme.primary),
            item('$alto', 'risco alto', CoresClinicas.alto),
            item('$atrasadas', 'medicações\natrasadas', atrasadas > 0 ? CoresClinicas.atrasada : CoresClinicas.ok),
            item('$alertas', 'com alerta\nnos SV', alertas > 0 ? CoresClinicas.medio : CoresClinicas.ok),
          ],
        ),
      ),
    );
  }
}

/// Card de leito: faixa colorida pelo risco, alergia e contador de pendências.
class CardPaciente extends ConsumerWidget {
  const CardPaciente({super.key, required this.paciente});

  final PacienteResumo paciente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = paciente;
    final corRisco = CoresClinicas.risco(p.risco);
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PacienteDetalheScreen(pacienteId: p.id, setorId: p.setorId),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                color: corRisco,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bed, color: Colors.white, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      p.leito.split('-').last,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(p.risco.rotulo, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (p.temAlergia)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Tooltip(
                                message: 'Paciente com alergia',
                                child: Icon(Icons.warning_amber_rounded, color: CoresClinicas.alto),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${p.leito} · ${p.idade} ${p.idade == 1 ? 'ano' : 'anos'} · ${p.sexo}',
                        style: tema.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(p.diagnostico, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (p.temAlergia || p.medicacoesAtrasadas > 0 || p.alertas.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (p.temAlergia) EtiquetaAlergia(p.alergias),
                            if (p.medicacoesAtrasadas > 0)
                              Etiqueta(
                                texto: '${p.medicacoesAtrasadas} medicação(ões) atrasada(s)',
                                cor: CoresClinicas.atrasada,
                                icone: Icons.alarm,
                              ),
                            for (final a in p.alertas.take(2))
                              Etiqueta(texto: a, cor: CoresClinicas.medio, icone: Icons.monitor_heart_outlined),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: p.pendencias > 0
                      ? Contador(
                          valor: p.pendencias,
                          cor: p.medicacoesAtrasadas > 0 ? CoresClinicas.atrasada : CoresClinicas.medio,
                          tooltip: '${p.pendencias} pendência(s)',
                        )
                      : const Icon(Icons.check_circle, color: CoresClinicas.ok),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
