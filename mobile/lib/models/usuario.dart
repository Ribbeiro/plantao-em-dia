import 'json_utils.dart';
import 'setor.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.usuario,
    required this.nome,
    required this.cargo,
    required this.setorId,
    this.registro,
    this.setor,
  });

  final String id;
  final String usuario;
  final String nome;
  final String cargo;
  final String setorId;
  final String? registro;
  final Setor? setor;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: jsonString(json['id']),
    usuario: jsonString(json['usuario']),
    nome: jsonString(json['nome']),
    cargo: jsonString(json['cargo']),
    setorId: jsonString(json['setorId']),
    registro: jsonStringOuNulo(json['registro']),
    setor: json['setor'] is Map ? Setor.fromJson(Map<String, dynamic>.from(json['setor'] as Map)) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario': usuario,
    'nome': nome,
    'cargo': cargo,
    'setorId': setorId,
    'registro': registro,
    if (setor != null) 'setor': setor!.toJson(),
  };

  /// Iniciais para o avatar (ex.: "Ana Ribeiro" → "AR").
  String get iniciais {
    final partes = nome.replaceAll(RegExp(r'^(Dra?\.)\s*'), '').split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
