import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movimentacao.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import 'paciente_detalhe_screen.dart';
import 'passagem_plantao_screen.dart';

/// Tela 8 – Histórico do setor: plantões encerrados (GET /plantoes?setor=)
/// e saídas recentes de pacientes (GET /setores/:id/altas).
class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key, required this.setorId});

  final String setorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantoes = historicoProvider(setorId);
    final saidas = saidasProvider(setorId);
    final historico = ref.watch(plantoes);
    final listaSaidas = ref.watch(saidas).asData?.value ?? const <PacienteSaida>[];

    return EstadoAsync(
      valor: historico,
      aoTentarNovamente: () => ref.invalidate(plantoes),
      construtor: (lista) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(saidas);
          ref.invalidate(plantoes);
          await ref.read(plantoes.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            if (listaSaidas.isNotEmpty) ...[
              TituloSecao(
                'Saídas dos últimos 7 dias',
                icone: Icons.logout,
                trailing: Contador(valor: listaSaidas.length),
              ),
              for (final s in listaSaidas) _CardSaida(item: s, setorId: setorId),
            ],
            const TituloSecao('Plantões encerrados', icone: Icons.history),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('Nenhum plantão encerrado ainda. Use a aba "Plantão" para encerrar o seu turno.'),
              )
            else
              for (final p in lista) CardPlantao(plantao: p),
          ],
        ),
      ),
    );
  }
}

class _CardSaida extends StatelessWidget {
  const _CardSaida({required this.item, required this.setorId});

  final PacienteSaida item;
  final String setorId;

  @override
  Widget build(BuildContext context) {
    final s = item.saida;
    final cor = switch (s.tipo) {
      TipoSaida.alta => CoresClinicas.ok,
      TipoSaida.transferencia => Theme.of(context).colorScheme.primary,
      TipoSaida.obito => Colors.blueGrey,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PacienteDetalheScreen(pacienteId: item.id, setorId: setorId),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.15),
          child: Text(
            item.leito.split('-').last,
            style: TextStyle(color: cor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${dataHora(s.em)} · ${s.por}${s.destino.isEmpty ? '' : '\n${s.destino}'}'),
        isThreeLine: s.destino.isNotEmpty,
        trailing: Etiqueta(texto: s.tipo.rotulo, cor: cor),
      ),
    );
  }
}
