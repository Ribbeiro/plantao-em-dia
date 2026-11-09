import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/setor.dart';
import '../providers/providers.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import '../widgets/marca.dart';

/// Seleção do setor após o login (GET /setores).
class SelecionarSetorScreen extends ConsumerWidget {
  const SelecionarSetorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessaoProvider).usuario;
    final setores = ref.watch(setoresProvider);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FundoBarraClinica(),
        title: const Text('Escolha o setor'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessaoProvider.notifier).sair(),
          ),
        ],
      ),
      body: EstadoAsync<List<Setor>>(
        valor: setores,
        aoTentarNovamente: () => ref.invalidate(setoresProvider),
        estaVazio: (l) => l.isEmpty,
        mensagemVazio: 'Nenhum setor cadastrado.',
        construtor: (lista) => RefreshIndicator(
          onRefresh: () => ref.refresh(setoresProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (usuario != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Olá, ${usuario.nome.split(' ').first}! Em qual setor você está hoje?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              for (final s in lista) _CardSetor(setor: s, ehDoUsuario: s.id == usuario?.setorId),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSetor extends ConsumerWidget {
  const _CardSetor({required this.setor, required this.ehDoUsuario});

  final Setor setor;
  final bool ehDoUsuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(sessaoProvider.notifier).selecionarSetor(setor),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cores.primaryContainer,
                child: Icon(
                  setor.id == 'ped' ? Icons.child_care : Icons.local_hospital_outlined,
                  color: cores.onPrimaryContainer,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            setor.nome,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (ehDoUsuario) ...[
                          const SizedBox(width: 8),
                          Etiqueta(texto: 'Meu setor', cor: cores.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${setor.andar} · ${setor.pacientes} pacientes / ${setor.leitos} leitos'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (setor.riscoAlto > 0)
                          Etiqueta(texto: '${setor.riscoAlto} risco alto', cor: CoresClinicas.alto),
                        Etiqueta(
                          texto: '${setor.medicacoesAtrasadas} medicações atrasadas',
                          cor: setor.medicacoesAtrasadas > 0 ? CoresClinicas.atrasada : CoresClinicas.ok,
                          icone: Icons.medication_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
