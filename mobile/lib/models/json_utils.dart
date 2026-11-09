// Funções auxiliares para converter o JSON da API com segurança.

int jsonInt(Object? v, [int padrao = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? padrao;
  return padrao;
}

double jsonDouble(Object? v, [double padrao = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? padrao;
  return padrao;
}

String jsonString(Object? v, [String padrao = '']) => v is String ? v : padrao;

String? jsonStringOuNulo(Object? v) => v is String && v.isNotEmpty ? v : null;

/// Datas chegam em ISO 8601 (UTC) e são exibidas no horário local do aparelho.
DateTime jsonData(Object? v) => v is String ? DateTime.parse(v).toLocal() : DateTime.fromMillisecondsSinceEpoch(0);

DateTime? jsonDataOuNula(Object? v) => v is String && v.isNotEmpty ? DateTime.parse(v).toLocal() : null;

List<String> jsonListaString(Object? v) => v is List ? v.whereType<String>().toList() : const [];

List<T> jsonLista<T>(Object? v, T Function(Map<String, dynamic>) fromJson) =>
    v is List ? v.whereType<Map>().map((e) => fromJson(Map<String, dynamic>.from(e))).toList() : <T>[];
