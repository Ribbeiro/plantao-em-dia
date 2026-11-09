import 'json_utils.dart';

enum Gravidade {
  leve('Leve'),
  moderada('Moderada'),
  grave('Grave');

  const Gravidade(this.rotulo);
  final String rotulo;

  static Gravidade fromString(String? v) => switch (v) {
    'grave' => Gravidade.grave,
    'moderada' => Gravidade.moderada,
    _ => Gravidade.leve,
  };
}

class Intercorrencia {
  const Intercorrencia({
    required this.id,
    required this.pacienteId,
    required this.descricao,
    required this.gravidade,
    required this.horario,
    this.responsavel,
  });

  final String id;
  final String pacienteId;
  final String descricao;
  final Gravidade gravidade;
  final DateTime horario;
  final String? responsavel;

  factory Intercorrencia.fromJson(Map<String, dynamic> json) => Intercorrencia(
    id: jsonString(json['id']),
    pacienteId: jsonString(json['pacienteId']),
    descricao: jsonString(json['descricao']),
    gravidade: Gravidade.fromString(json['gravidade'] as String?),
    horario: jsonData(json['horario']),
    responsavel: jsonStringOuNulo(json['responsavel']),
  );
}
