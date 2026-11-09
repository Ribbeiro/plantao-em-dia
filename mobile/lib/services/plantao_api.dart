import '../models/intercorrencia.dart';
import '../models/json_utils.dart';
import '../models/medicacao.dart';
import '../models/paciente.dart';
import '../models/pendencia.dart';
import '../models/plantao.dart';
import '../models/setor.dart';
import '../models/sinais_vitais.dart';
import '../models/usuario.dart';
import 'api_client.dart';

/// Todos os endpoints da API do Plantão em Dia.
class PlantaoApi {
  PlantaoApi(this._c);

  final ApiClient _c;

  Map<String, dynamic> _mapa(Object? v) => Map<String, dynamic>.from(v as Map);

  Future<(String, Usuario)> login(String usuario, String senha) async {
    final r = _mapa(await _c.post<dynamic>('/auth/login', {'usuario': usuario, 'senha': senha}));
    return (r['token'] as String, Usuario.fromJson(_mapa(r['usuario'])));
  }

  Future<List<Setor>> setores() async => jsonLista(await _c.get<dynamic>('/setores'), Setor.fromJson);

  Future<List<PacienteResumo>> pacientes(String setorId) async =>
      jsonLista(await _c.get<dynamic>('/setores/$setorId/pacientes'), PacienteResumo.fromJson);

  Future<PacienteDetalhe> paciente(String id) async =>
      PacienteDetalhe.fromJson(_mapa(await _c.get<dynamic>('/pacientes/$id')));

  Future<SinaisVitais> registrarSinais(
    String pacienteId, {
    required int pas,
    required int pad,
    required int fc,
    required int fr,
    required double temperatura,
    required int satO2,
    required int dor,
    String observacao = '',
  }) async => SinaisVitais.fromJson(
    _mapa(
      await _c.post<dynamic>('/pacientes/$pacienteId/sinais-vitais', {
        'pas': pas,
        'pad': pad,
        'fc': fc,
        'fr': fr,
        'temperatura': temperatura,
        'satO2': satO2,
        'dor': dor,
        'observacao': observacao,
      }),
    ),
  );

  Future<Intercorrencia> registrarIntercorrencia(
    String pacienteId, {
    required String descricao,
    required Gravidade gravidade,
    DateTime? horario,
  }) async => Intercorrencia.fromJson(
    _mapa(
      await _c.post<dynamic>('/pacientes/$pacienteId/intercorrencias', {
        'descricao': descricao,
        'gravidade': gravidade.name,
        if (horario != null) 'horario': horario.toUtc().toIso8601String(),
      }),
    ),
  );

  Future<Medicacao> administrar(String medicacaoId) async =>
      Medicacao.fromJson(_mapa(await _c.patch<dynamic>('/medicacoes/$medicacaoId', {'status': 'administrada'})));

  Future<Medicacao> desfazerAdministracao(String medicacaoId) async =>
      Medicacao.fromJson(_mapa(await _c.patch<dynamic>('/medicacoes/$medicacaoId', {'status': 'pendente'})));

  Future<Pendencia> concluirPendencia(String id, {bool concluida = true}) async => Pendencia.fromJson(
    _mapa(await _c.patch<dynamic>('/pendencias/$id', {'status': concluida ? 'concluida' : 'pendente'})),
  );

  Future<PendenciasSetor> pendencias(String setorId) async =>
      PendenciasSetor.fromJson(_mapa(await _c.get<dynamic>('/pendencias', query: {'setor': setorId})));

  Future<Plantao> encerrarTurno(String setorId, {String observacoes = ''}) async =>
      Plantao.fromJson(_mapa(await _c.post<dynamic>('/plantoes', {'setorId': setorId, 'observacoes': observacoes})));

  Future<Plantao> plantao(String id) async => Plantao.fromJson(_mapa(await _c.get<dynamic>('/plantoes/$id')));

  Future<Plantao> confirmarLeitura(String id) async =>
      Plantao.fromJson(_mapa(await _c.post<dynamic>('/plantoes/$id/confirmar')));

  Future<List<Plantao>> historico(String setorId) async =>
      jsonLista(await _c.get<dynamic>('/plantoes', query: {'setor': setorId}), Plantao.fromJson);
}
