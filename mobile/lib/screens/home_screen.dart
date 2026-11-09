import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/notificacoes_service.dart';
import '../widgets/marca.dart';
import 'admitir_paciente_screen.dart';
import 'historico_screen.dart';
import 'passagem_plantao_screen.dart';
import 'pacientes_screen.dart';
import 'pendencias_screen.dart';

/// Estrutura principal: navegação inferior entre as áreas do setor.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _aba = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Verifica medicações atrasadas agora e a cada 5 minutos (notificação local).
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarAtrasadas());
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _verificarAtrasadas());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verificarAtrasadas() async {
    final notif = NotificacoesService.instancia;
    final setor = ref.read(sessaoProvider).setor;
    if (!notif.suportado || setor == null) return;
    try {
      await notif.iniciar();
      final p = await ref.read(apiProvider).pendencias(setor.id);
      await notif.avisarAtrasadas(setorNome: setor.nome, idsAtrasadas: p.medicacoesAtrasadas.map((m) => m.id).toList());
    } catch (_) {
      // Falha silenciosa: a tela de pendências mostra o erro quando aberta.
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessao = ref.watch(sessaoProvider);
    final setor = sessao.setor;
    final usuario = sessao.usuario;
    // Durante a animação de saída (logout/troca de setor) a sessão já foi limpa.
    if (setor == null || usuario == null) return const Scaffold();

    final abas = <Widget>[
      PacientesScreen(setorId: setor.id),
      PendenciasScreen(setorId: setor.id),
      PassagemPlantaoScreen(setorId: setor.id),
      HistoricoScreen(setorId: setor.id),
    ];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FundoBarraClinica(),
        titleSpacing: 0,
        leading: const Padding(padding: EdgeInsets.all(10), child: LogoPlantao(contorno: true)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(setor.nome),
            Text(
              '${usuario.nome} · ${usuario.cargo}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Trocar setor',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => ref.read(sessaoProvider.notifier).trocarSetor(),
          ),
          PopupMenuButton<String>(
            tooltip: 'Conta',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
              child: Text(usuario.iniciais, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            onSelected: (v) {
              if (v == 'sair') ref.read(sessaoProvider.notifier).sair();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text('${usuario.nome}\n${usuario.registro ?? usuario.cargo}')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sair',
                child: ListTile(leading: Icon(Icons.logout), title: Text('Sair')),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: abas[_aba],
      floatingActionButton: _aba == 0
          ? FloatingActionButton.extended(
              heroTag: 'admitir',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdmitirPacienteScreen(setorId: setor.id, setorNome: setor.nome),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Admitir'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bed_outlined), selectedIcon: Icon(Icons.bed), label: 'Pacientes'),
          NavigationDestination(
            icon: Icon(Icons.pending_actions_outlined),
            selectedIcon: Icon(Icons.pending_actions),
            label: 'Pendências',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_information_outlined),
            selectedIcon: Icon(Icons.medical_information),
            label: 'Plantão',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }
}
