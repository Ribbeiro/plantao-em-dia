import 'package:intl/intl.dart';

final _hora = DateFormat('HH:mm', 'pt_BR');
final _dataHora = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
final _dataCompleta = DateFormat("EEEE, dd/MM/yyyy 'às' HH:mm", 'pt_BR');

String hora(DateTime d) => _hora.format(d);

String dataHora(DateTime d) => _dataHora.format(d);

String dataCompleta(DateTime d) => _dataCompleta.format(d);

/// "há 5 min", "há 2 h", "em 40 min"...
String relativo(DateTime d, {DateTime? agora}) {
  final ref = agora ?? DateTime.now();
  final diff = d.difference(ref);
  final passado = diff.isNegative;
  final m = diff.inMinutes.abs();
  final String texto;
  if (m < 1) {
    return 'agora';
  } else if (m < 60) {
    texto = '$m min';
  } else if (m < 60 * 24) {
    final h = m ~/ 60;
    final resto = m % 60;
    texto = resto == 0 || h >= 6 ? '$h h' : '${h}h${resto.toString().padLeft(2, '0')}';
  } else {
    texto = '${m ~/ (60 * 24)} dia(s)';
  }
  return passado ? 'há $texto' : 'em $texto';
}

/// Converte texto digitado (aceita vírgula) em número.
double? numeroDigitado(String? texto) =>
    texto == null || texto.trim().isEmpty ? null : double.tryParse(texto.trim().replaceAll(',', '.'));
