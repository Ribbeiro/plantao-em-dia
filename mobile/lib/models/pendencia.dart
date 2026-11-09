import 'json_utils.dart';
import 'medicacao.dart';
import 'paciente.dart';

class Pendencia {
  const Pendencia({
    required this.id,
    required this.pacienteId,
    required this.tipo,
    required this.descricao,
    required this.prazo,
    required this.status,
    this.vencida = false,
    this.paciente,
  });

  final String id;
  final String pacienteId;

  /// "exame", "procedimento" ou "retorno".
  final String tipo;
  final String descricao;
  final DateTime prazo;

  /// "pendente" ou "concluida".
  final String status;
  final bool vencida;
  final PacienteRef? paciente;

  bool get concluida => status == 'concluida';

  String get tipoRotulo => switch (tipo) {
    'exame' => 'Exame',
    'procedimento' => 'Procedimento',
    'retorno' => 'Retorno/parecer',
    _ => tipo,
  };

  factory Pendencia.fromJson(Map<String, dynamic> json) => Pendencia(
    id: jsonString(json['id']),
    pacienteId: jsonString(json['pacienteId']),
    tipo: jsonString(json['tipo']),
    descricao: jsonString(json['descricao']),
    prazo: jsonData(json['prazo']),
    status: jsonString(json['status'], 'pendente'),
    vencida: json['vencida'] == true,
    paciente: json['paciente'] is Map ? PacienteRef.fromJson(Map<String, dynamic>.from(json['paciente'] as Map)) : null,
  );
}

/// Resposta de GET /pendencias?setor=
class PendenciasSetor {
  const PendenciasSetor({
    required this.total,
    required this.medicacoesAtrasadas,
    required this.exames,
    required this.procedimentos,
    required this.retornos,
  });

  final int total;
  final List<Medicacao> medicacoesAtrasadas;
  final List<Pendencia> exames;
  final List<Pendencia> procedimentos;
  final List<Pendencia> retornos;

  bool get vazio => total == 0;

  factory PendenciasSetor.fromJson(Map<String, dynamic> json) => PendenciasSetor(
    total: jsonInt(json['total']),
    medicacoesAtrasadas: jsonLista(json['medicacoesAtrasadas'], Medicacao.fromJson),
    exames: jsonLista(json['exames'], Pendencia.fromJson),
    procedimentos: jsonLista(json['procedimentos'], Pendencia.fromJson),
    retornos: jsonLista(json['retornos'], Pendencia.fromJson),
  );
}
