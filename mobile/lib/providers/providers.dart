import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movimentacao.dart';
import '../models/paciente.dart';
import '../models/pendencia.dart';
import '../models/plantao.dart';
import '../models/setor.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';
import '../services/armazenamento.dart';
import '../services/notificacoes_service.dart';
import '../services/plantao_api.dart';

// ---------------------------------------------------------------------------
// Infraestrutura
// ---------------------------------------------------------------------------

final armazenamentoProvider = Provider<Armazenamento>((ref) => Armazenamento());

/// URL da API em uso (padrão da plataforma ou a configurada pelo usuário).
class ApiUrlNotifier extends Notifier<String> {
  @override
  String build() => ApiConfig.padrao;

  Future<void> carregar() async {
    final salva = await ref.read(armazenamentoProvider).lerApiUrl();
    if (salva != null && salva.isNotEmpty) state = salva;
  }

  Future<void> definir(String? url) async {
    final limpa = url?.trim().replaceAll(RegExp(r'/+$'), '');
    await ref.read(armazenamentoProvider).salvarApiUrl(limpa);
    state = (limpa == null || limpa.isEmpty) ? ApiConfig.padrao : limpa;
  }
}

final apiUrlProvider = NotifierProvider<ApiUrlNotifier, String>(ApiUrlNotifier.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: ref.read(apiUrlProvider),
    lerToken: () => ref.read(sessaoProvider).token,
    aoExpirarSessao: () => ref.read(sessaoProvider.notifier).sair(mensagem: 'Sua sessão expirou. Entre novamente.'),
  );
  ref.listen(apiUrlProvider, (_, url) => client.baseUrl = url);
  return client;
});

final apiProvider = Provider<PlantaoApi>((ref) => PlantaoApi(ref.watch(apiClientProvider)));

// ---------------------------------------------------------------------------
// Sessão (login + setor selecionado)
// ---------------------------------------------------------------------------

class EstadoSessao {
  const EstadoSessao({this.token, this.usuario, this.setor, this.mensagem});

  final String? token;
  final Usuario? usuario;
  final Setor? setor;

  /// Mensagem exibida na tela de login (ex.: sessão expirada).
  final String? mensagem;

  bool get logado => token != null && usuario != null;
}

class SessaoNotifier extends Notifier<EstadoSessao> {
  @override
  EstadoSessao build() => const EstadoSessao();

  Armazenamento get _arm => ref.read(armazenamentoProvider);

  /// Restaura a sessão salva (chamado no main antes de abrir o app).
  Future<void> restaurar() async {
    final salva = await _arm.lerSessao();
    if (salva == null) return;
    final (token, usuario) = salva;
    if (tokenExpirado(token)) {
      await _arm.limparSessao();
      return;
    }
    final setorId = await _arm.lerSetor();
    Setor? setor;
    if (setorId != null && usuario.setor?.id == setorId) setor = usuario.setor;
    if (setorId != null && setor == null) setor = Setor(id: setorId, nome: _nomePadrao(setorId));
    state = EstadoSessao(token: token, usuario: usuario, setor: setor);
  }

  String _nomePadrao(String id) => switch (id) {
    'cm' => 'Clínica Médica',
    'ped' => 'Pediatria',
    _ => id,
  };

  Future<void> entrar(String usuario, String senha) async {
    final (token, u) = await ref.read(apiProvider).login(usuario, senha);
    await _arm.salvarSessao(token, u);
    state = EstadoSessao(token: token, usuario: u);
  }

  Future<void> selecionarSetor(Setor setor) async {
    await _arm.salvarSetor(setor.id);
    state = EstadoSessao(token: state.token, usuario: state.usuario, setor: setor);
  }

  void trocarSetor() => state = EstadoSessao(token: state.token, usuario: state.usuario);

  Future<void> sair({String? mensagem}) async {
    if (!state.logado && mensagem == null) return;
    NotificacoesService.instancia.limpar();
    state = EstadoSessao(mensagem: mensagem);
    await _arm.limparSessao();
  }
}

final sessaoProvider = NotifierProvider<SessaoNotifier, EstadoSessao>(SessaoNotifier.new);

// ---------------------------------------------------------------------------
// Dados vindos da API
// ---------------------------------------------------------------------------

final setoresProvider = FutureProvider.autoDispose<List<Setor>>((ref) => ref.watch(apiProvider).setores());

final pacientesProvider = FutureProvider.autoDispose.family<List<PacienteResumo>, String>(
  (ref, setorId) => ref.watch(apiProvider).pacientes(setorId),
);

final pacienteProvider = FutureProvider.autoDispose.family<PacienteDetalhe, String>(
  (ref, id) => ref.watch(apiProvider).paciente(id),
);

final leitosProvider = FutureProvider.autoDispose.family<List<Leito>, String>(
  (ref, setorId) => ref.watch(apiProvider).leitos(setorId),
);

final saidasProvider = FutureProvider.autoDispose.family<List<PacienteSaida>, String>(
  (ref, setorId) => ref.watch(apiProvider).saidasRecentes(setorId),
);

final pendenciasProvider = FutureProvider.autoDispose.family<PendenciasSetor, String>(
  (ref, setorId) => ref.watch(apiProvider).pendencias(setorId),
);

final historicoProvider = FutureProvider.autoDispose.family<List<Plantao>, String>(
  (ref, setorId) => ref.watch(apiProvider).historico(setorId),
);

final plantaoProvider = FutureProvider.autoDispose.family<Plantao, String>(
  (ref, id) => ref.watch(apiProvider).plantao(id),
);

/// Recarrega tudo que depende dos registros de um paciente/setor.
void atualizarDadosDoSetor(WidgetRef ref, String setorId, {String? pacienteId}) {
  ref.invalidate(pacientesProvider(setorId));
  ref.invalidate(pendenciasProvider(setorId));
  ref.invalidate(leitosProvider(setorId));
  ref.invalidate(saidasProvider(setorId));
  ref.invalidate(setoresProvider);
  if (pacienteId != null) ref.invalidate(pacienteProvider(pacienteId));
}
