import 'json_utils.dart';
import 'movimentacao.dart';
import 'paciente.dart';

class Profissional {
  const Profissional({required this.id, required this.nome, required this.cargo});

  final String id;
  final String nome;
  final String cargo;

  factory Profissional.fromJson(Map<String, dynamic> json) => Profissional(
    id: jsonString(json['id'] ?? json['usuarioId']),
    nome: jsonString(json['nome']),
    cargo: jsonString(json['cargo']),
  );
}

class Confirmacao {
  const Confirmacao({required this.profissional, required this.confirmadoEm});

  final Profissional profissional;
  final DateTime confirmadoEm;

  factory Confirmacao.fromJson(Map<String, dynamic> json) =>
      Confirmacao(profissional: Profissional.fromJson(json), confirmadoEm: jsonData(json['confirmadoEm']));
}

/// Resumo SBAR de um paciente.
class SbarPaciente {
  const SbarPaciente({
    required this.pacienteId,
    required this.nome,
    required this.leito,
    required this.risco,
    required this.alergias,
    required this.situacao,
    required this.breveHistorico,
    required this.avaliacao,
    required this.recomendacao,
    required this.alertas,
    required this.medicacoesAtrasadas,
    required this.pendenciasAbertas,
  });

  final String pacienteId;
  final String nome;
  final String leito;
  final Risco risco;
  final List<String> alergias;
  final String situacao;
  final String breveHistorico;
  final String avaliacao;
  final String recomendacao;
  final List<String> alertas;
  final int medicacoesAtrasadas;
  final int pendenciasAbertas;

  bool get precisaAtencao => risco == Risco.alto || alertas.isNotEmpty || medicacoesAtrasadas > 0;

  factory SbarPaciente.fromJson(Map<String, dynamic> json) => SbarPaciente(
    pacienteId: jsonString(json['pacienteId']),
    nome: jsonString(json['nome']),
    leito: jsonString(json['leito']),
    risco: Risco.fromString(json['risco'] as String?),
    alergias: jsonListaString(json['alergias']),
    situacao: jsonString(json['situacao']),
    breveHistorico: jsonString(json['breveHistorico']),
    avaliacao: jsonString(json['avaliacao']),
    recomendacao: jsonString(json['recomendacao']),
    alertas: jsonListaString(json['alertas']),
    medicacoesAtrasadas: jsonInt(json['medicacoesAtrasadas']),
    pendenciasAbertas: jsonInt(json['pendenciasAbertas']),
  );

  /// Texto pronto para copiar/compartilhar.
  String get texto =>
      'Leito $leito – $nome\n'
      'S: $situacao\nB: $breveHistorico\nA: $avaliacao\nR: $recomendacao';
}

class TotaisPlantao {
  const TotaisPlantao({this.pacientes = 0, this.medicacoesAtrasadas = 0, this.pendencias = 0, this.comAlerta = 0});

  final int pacientes;
  final int medicacoesAtrasadas;
  final int pendencias;
  final int comAlerta;

  factory TotaisPlantao.fromJson(Map<String, dynamic> json) => TotaisPlantao(
    pacientes: jsonInt(json['pacientes']),
    medicacoesAtrasadas: jsonInt(json['medicacoesAtrasadas']),
    pendencias: jsonInt(json['pendencias']),
    comAlerta: jsonInt(json['comAlerta']),
  );
}

class Plantao {
  const Plantao({
    required this.id,
    required this.setorId,
    required this.setorNome,
    required this.responsavel,
    required this.inicio,
    required this.fim,
    required this.totais,
    this.observacoes = '',
    this.resumo = const [],
    this.confirmacao,
    this.movimentacoes = const Movimentacoes(),
  });

  /// Admissões e saídas do setor durante o turno.
  final Movimentacoes movimentacoes;

  final String id;
  final String setorId;
  final String setorNome;
  final Profissional responsavel;
  final DateTime inicio;
  final DateTime fim;
  final String observacoes;
  final TotaisPlantao totais;

  /// Vem vazio na listagem do histórico; completo em GET /plantoes/:id.
  final List<SbarPaciente> resumo;
  final Confirmacao? confirmacao;

  bool get confirmado => confirmacao != null;

  factory Plantao.fromJson(Map<String, dynamic> json) => Plantao(
    id: jsonString(json['id']),
    setorId: jsonString(json['setorId']),
    setorNome: jsonString(json['setorNome']),
    responsavel: json['responsavel'] is Map
        ? Profissional.fromJson(Map<String, dynamic>.from(json['responsavel'] as Map))
        : const Profissional(id: '', nome: '?', cargo: ''),
    inicio: jsonData(json['inicio']),
    fim: jsonData(json['fim']),
    observacoes: jsonString(json['observacoes']),
    totais: json['totais'] is Map
        ? TotaisPlantao.fromJson(Map<String, dynamic>.from(json['totais'] as Map))
        : const TotaisPlantao(),
    resumo: jsonLista(json['resumo'], SbarPaciente.fromJson),
    confirmacao: json['confirmacao'] is Map
        ? Confirmacao.fromJson(Map<String, dynamic>.from(json['confirmacao'] as Map))
        : null,
    movimentacoes: Movimentacoes.deJson(json['movimentacoes']),
  );
}
