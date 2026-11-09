import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plantao.dart';
import '../providers/providers.dart';
import '../widgets/estado_async.dart';
import 'passagem_plantao_screen.dart';

/// Tela 8 – Histórico de plantões do setor (GET /plantoes?setor=).
class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key, required this.setorId});

  final String setorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = historicoProvider(setorId);
    return EstadoAsync<List<Plantao>>(
      valor: ref.watch(provider),
      aoTentarNovamente: () => ref.invalidate(provider),
      estaVazio: (l) => l.isEmpty,
      mensagemVazio: 'Nenhum plantão encerrado ainda.\nUse a aba "Plantão" para encerrar o seu turno.',
      iconeVazio: Icons.history,
      construtor: (lista) => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: lista.length,
          itemBuilder: (_, i) => CardPlantao(plantao: lista[i]),
        ),
      ),
    );
  }
}
