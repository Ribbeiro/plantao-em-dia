import 'intercorrencia.dart';
import 'json_utils.dart';
import 'medicacao.dart';
import 'movimentacao.dart';
import 'pendencia.dart';
import 'sinais_vitais.dart';

enum Risco {
  baixo('Baixo'),
  medio('Médio'),
  alto('Alto');

  const Risco(this.rotulo);
  final String rotulo;

  static Risco fromString(String? valor) => switch (valor) {
    'alto' => Risco.alto,
    'medio' => Risco.medio,
    _ => Risco.baixo,
  };
}

/// Referência curta a um paciente (usada nas pendências do setor).
class PacienteRef {
  const PacienteRef({required this.id, required this.nome, required this.leito, required this.risco});

  final String id;
  final String nome;
  final String leito;
  final Risco risco;

  factory PacienteRef.fromJson(Map<String, dynamic> json) => PacienteRef(
    id: jsonString(json['id']),
    nome: jsonString(json['nome']),
    leito: jsonString(json['leito']),
    risco: Risco.fromString(json['risco'] as String?),
  );
}

/// Paciente como aparece na lista do setor.
class PacienteResumo {
  const PacienteResumo({
    required this.id,
    required this.setorId,
    required this.leito,
    required this.nome,
    required this.idade,
    required this.sexo,
    required this.diagnostico,
    required this.alergias,
    required this.risco,
    required this.medicacoesAtrasadas,
    required this.pendencias,
    required this.alertas,
  });

  final String id;
  final String setorId;
  final String leito;
  final String nome;
  final int idade;
  final String sexo;
  final String diagnostico;
  final List<String> alergias;
  final Risco risco;
  final int medicacoesAtrasadas;

  /// Medicações atrasadas + exames/procedimentos/retornos em aberto.
  final int pendencias;
  final List<String> alertas;

  bool get temAlergia => alergias.isNotEmpty;

  factory PacienteResumo.fromJson(Map<String, dynamic> json) => PacienteResumo(
    id: jsonString(json['id']),
    setorId: jsonString(json['setorId']),
    leito: jsonString(json['leito']),
    nome: jsonString(json['nome']),
    idade: jsonInt(json['idade']),
    sexo: jsonString(json['sexo']),
    diagnostico: jsonString(json['diagnostico']),
    alergias: jsonListaString(json['alergias']),
    risco: Risco.fromString(json['risco'] as String?),
    medicacoesAtrasadas: jsonInt(json['medicacoesAtrasadas']),
    pendencias: jsonInt(json['pendencias']),
    alertas: jsonListaString(json['alertas']),
  );
}

/// Paciente com prontuário resumido do turno.
class PacienteDetalhe extends PacienteResumo {
  const PacienteDetalhe({
    required super.id,
    required super.setorId,
    required super.leito,
    required super.nome,
    required super.idade,
    required super.sexo,
    required super.diagnostico,
    required super.alergias,
    required super.risco,
    required super.medicacoesAtrasadas,
    required super.pendencias,
    required super.alertas,
    required this.historico,
    required this.dispositivos,
    required this.dieta,
    required this.dataInternacao,
    required this.sinaisVitais,
    required this.medicacoes,
    required this.intercorrencias,
    required this.pendenciasLista,
    this.saida,
  });

  /// Preenchido quando o paciente já saiu do setor (alta, transferência ou óbito).
  final Saida? saida;

  bool get internado => saida == null;

  final String historico;
  final List<String> dispositivos;
  final String dieta;
  final DateTime dataInternacao;
  final List<SinaisVitais> sinaisVitais;
  final List<Medicacao> medicacoes;
  final List<Intercorrencia> intercorrencias;
  final List<Pendencia> pendenciasLista;

  SinaisVitais? get ultimosSinais => sinaisVitais.isEmpty ? null : sinaisVitais.first;

  factory PacienteDetalhe.fromJson(Map<String, dynamic> json) {
    final r = PacienteResumo.fromJson(json);
    return PacienteDetalhe(
      id: r.id,
      setorId: r.setorId,
      leito: r.leito,
      nome: r.nome,
      idade: r.idade,
      sexo: r.sexo,
      diagnostico: r.diagnostico,
      alergias: r.alergias,
      risco: r.risco,
      medicacoesAtrasadas: r.medicacoesAtrasadas,
      pendencias: r.pendencias,
      alertas: r.alertas,
      historico: jsonString(json['historico']),
      dispositivos: jsonListaString(json['dispositivos']),
      dieta: jsonString(json['dieta']),
      dataInternacao: jsonData(json['dataInternacao']),
      sinaisVitais: jsonLista(json['sinaisVitais'], SinaisVitais.fromJson),
      medicacoes: jsonLista(json['medicacoes'], Medicacao.fromJson),
      intercorrencias: jsonLista(json['intercorrencias'], Intercorrencia.fromJson),
      pendenciasLista: jsonLista(json['pendenciasLista'], Pendencia.fromJson),
      saida: Saida.deJson(json['alta']),
    );
  }
}
