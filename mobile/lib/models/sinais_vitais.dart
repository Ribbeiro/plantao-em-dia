import 'json_utils.dart';

class SinaisVitais {
  const SinaisVitais({
    required this.id,
    required this.pacienteId,
    required this.pas,
    required this.pad,
    required this.fc,
    required this.fr,
    required this.temperatura,
    required this.satO2,
    required this.dor,
    required this.registradoEm,
    this.observacao = '',
    this.responsavel,
  });

  final String id;
  final String pacienteId;
  final int pas;
  final int pad;
  final int fc;
  final int fr;
  final double temperatura;
  final int satO2;
  final int dor;
  final String observacao;
  final DateTime registradoEm;
  final String? responsavel;

  factory SinaisVitais.fromJson(Map<String, dynamic> json) => SinaisVitais(
    id: jsonString(json['id']),
    pacienteId: jsonString(json['pacienteId']),
    pas: jsonInt(json['pas']),
    pad: jsonInt(json['pad']),
    fc: jsonInt(json['fc']),
    fr: jsonInt(json['fr']),
    temperatura: jsonDouble(json['temperatura']),
    satO2: jsonInt(json['satO2']),
    dor: jsonInt(json['dor']),
    observacao: jsonString(json['observacao']),
    registradoEm: jsonData(json['registradoEm']),
    responsavel: jsonStringOuNulo(json['responsavel']),
  );

  List<String> get alertas =>
      alertasSinaisVitais(pas: pas, pad: pad, fc: fc, fr: fr, temperatura: temperatura, satO2: satO2, dor: dor);
}

/// Mesmas faixas de alerta usadas pela API, para dar retorno visual
/// enquanto o profissional ainda está preenchendo o formulário.
List<String> alertasSinaisVitais({int? pas, int? pad, int? fc, int? fr, double? temperatura, int? satO2, int? dor}) {
  final a = <String>[];
  if (satO2 != null && satO2 < 92) a.add('SatO2 baixa ($satO2%)');
  if (fc != null && fc > 120) a.add('Taquicardia (FC $fc)');
  if (fc != null && fc < 50) a.add('Bradicardia (FC $fc)');
  if (pas != null && pas >= 160) a.add('PA elevada ($pas/${pad ?? '-'})');
  if (pas != null && pas < 90) a.add('Hipotensão ($pas/${pad ?? '-'})');
  if (temperatura != null && temperatura >= 37.8) a.add('Febre (${temperatura.toStringAsFixed(1)} °C)');
  if (fr != null && fr > 24) a.add('Taquipneia (FR $fr)');
  if (dor != null && dor >= 7) a.add('Dor intensa ($dor/10)');
  return a;
}
