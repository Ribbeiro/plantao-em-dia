import 'json_utils.dart';

/// Como o paciente saiu do setor.
enum TipoSaida {
  alta('Alta hospitalar', 'alta'),
  transferencia('Transferência', 'transferencia'),
  obito('Óbito', 'obito');

  const TipoSaida(this.rotulo, this.valor);
  final String rotulo;
  final String valor;

  static TipoSaida fromString(String? v) => switch (v) {
    'transferencia' => TipoSaida.transferencia,
    'obito' => TipoSaida.obito,
    _ => TipoSaida.alta,
  };
}

/// Registro de saída (alta, transferência ou óbito).
class Saida {
  const Saida({required this.tipo, required this.em, required this.por, this.destino = '', this.observacao = ''});

  final TipoSaida tipo;
  final DateTime em;
  final String por;
  final String destino;
  final String observacao;

  factory Saida.fromJson(Map<String, dynamic> json) => Saida(
    tipo: TipoSaida.fromString(json['tipo'] as String?),
    em: jsonData(json['em']),
    por: jsonString(json['por']),
    destino: jsonString(json['destino']),
    observacao: jsonString(json['observacao']),
  );

  static Saida? deJson(Object? v) => v is Map ? Saida.fromJson(Map<String, dynamic>.from(v)) : null;
}

/// Leito do setor no mapa de ocupação (GET /setores/:id/leitos).
class Leito {
  const Leito({required this.leito, required this.ocupado, this.pacienteNome});

  final String leito;
  final bool ocupado;
  final String? pacienteNome;

  factory Leito.fromJson(Map<String, dynamic> json) => Leito(
    leito: jsonString(json['leito']),
    ocupado: json['ocupado'] == true,
    pacienteNome: json['paciente'] is Map ? jsonStringOuNulo((json['paciente'] as Map)['nome']) : null,
  );
}

/// Paciente que saiu do setor recentemente (GET /setores/:id/altas).
class PacienteSaida {
  const PacienteSaida({
    required this.id,
    required this.nome,
    required this.leito,
    required this.idade,
    required this.diagnostico,
    required this.saida,
  });

  final String id;
  final String nome;
  final String leito;
  final int idade;
  final String diagnostico;
  final Saida saida;

  factory PacienteSaida.fromJson(Map<String, dynamic> json) => PacienteSaida(
    id: jsonString(json['id']),
    nome: jsonString(json['nome']),
    leito: jsonString(json['leito']),
    idade: jsonInt(json['idade']),
    diagnostico: jsonString(json['diagnostico']),
    saida: Saida.deJson(json['alta']) ?? Saida(tipo: TipoSaida.alta, em: DateTime(1970), por: ''),
  );
}

/// Admissões e saídas que aconteceram durante o turno (vão no resumo do plantão).
class Movimentacoes {
  const Movimentacoes({this.admissoes = const [], this.saidas = const []});

  final List<MovimentoLeito> admissoes;
  final List<MovimentoLeito> saidas;

  bool get vazio => admissoes.isEmpty && saidas.isEmpty;

  factory Movimentacoes.fromJson(Map<String, dynamic> json) => Movimentacoes(
    admissoes: jsonLista(json['admissoes'], MovimentoLeito.fromJson),
    saidas: jsonLista(json['saidas'], MovimentoLeito.fromJson),
  );

  static Movimentacoes deJson(Object? v) =>
      v is Map ? Movimentacoes.fromJson(Map<String, dynamic>.from(v)) : const Movimentacoes();
}

class MovimentoLeito {
  const MovimentoLeito({
    required this.leito,
    required this.nome,
    required this.por,
    required this.em,
    this.tipo,
    this.destino = '',
  });

  final String leito;
  final String nome;
  final String por;
  final DateTime em;

  /// Só nas saídas.
  final TipoSaida? tipo;
  final String destino;

  factory MovimentoLeito.fromJson(Map<String, dynamic> json) => MovimentoLeito(
    leito: jsonString(json['leito']),
    nome: jsonString(json['nome']),
    por: jsonString(json['por']),
    em: jsonData(json['em']),
    tipo: json['tipo'] is String ? TipoSaida.fromString(json['tipo'] as String) : null,
    destino: jsonString(json['destino']),
  );
}
