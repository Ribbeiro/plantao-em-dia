import 'json_utils.dart';

class Setor {
  const Setor({
    required this.id,
    required this.nome,
    this.andar = '',
    this.leitos = 0,
    this.pacientes = 0,
    this.riscoAlto = 0,
    this.medicacoesAtrasadas = 0,
  });

  final String id;
  final String nome;
  final String andar;
  final int leitos;
  final int pacientes;
  final int riscoAlto;
  final int medicacoesAtrasadas;

  factory Setor.fromJson(Map<String, dynamic> json) => Setor(
    id: jsonString(json['id']),
    nome: jsonString(json['nome']),
    andar: jsonString(json['andar']),
    leitos: jsonInt(json['leitos']),
    pacientes: jsonInt(json['pacientes']),
    riscoAlto: jsonInt(json['riscoAlto']),
    medicacoesAtrasadas: jsonInt(json['medicacoesAtrasadas']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'andar': andar, 'leitos': leitos};
}
