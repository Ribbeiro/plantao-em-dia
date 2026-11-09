import 'json_utils.dart';
import 'paciente.dart';

class Medicacao {
  const Medicacao({
    required this.id,
    required this.pacienteId,
    required this.nome,
    required this.dose,
    required this.via,
    required this.horario,
    required this.status,
    required this.atrasada,
    this.administradaEm,
    this.responsavel,
    this.paciente,
  });

  final String id;
  final String pacienteId;
  final String nome;
  final String dose;
  final String via;
  final DateTime horario;

  /// "pendente" ou "administrada".
  final String status;

  /// Calculado pela API: pendente e com o horário (mais a tolerância) já vencido.
  final bool atrasada;
  final DateTime? administradaEm;
  final String? responsavel;

  /// Preenchido apenas em GET /pendencias.
  final PacienteRef? paciente;

  bool get administrada => status == 'administrada';

  String get descricao => '$nome $dose · $via';

  factory Medicacao.fromJson(Map<String, dynamic> json) => Medicacao(
    id: jsonString(json['id']),
    pacienteId: jsonString(json['pacienteId']),
    nome: jsonString(json['nome']),
    dose: jsonString(json['dose']),
    via: jsonString(json['via']),
    horario: jsonData(json['horario']),
    status: jsonString(json['status'], 'pendente'),
    atrasada: json['atrasada'] == true,
    administradaEm: jsonDataOuNula(json['administradaEm']),
    responsavel: jsonStringOuNulo(json['responsavel']),
    paciente: json['paciente'] is Map ? PacienteRef.fromJson(Map<String, dynamic>.from(json['paciente'] as Map)) : null,
  );
}
