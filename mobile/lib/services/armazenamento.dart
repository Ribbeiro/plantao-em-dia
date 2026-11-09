import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/usuario.dart';

/// Guarda o token JWT e a sessão de forma segura (Keystore/Keychain).
class Armazenamento {
  Armazenamento([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'token';
  static const _kUsuario = 'usuario';
  static const _kSetor = 'setor_selecionado';
  static const _kApiUrl = 'api_url';

  Future<void> salvarSessao(String token, Usuario usuario) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUsuario, value: jsonEncode(usuario.toJson()));
  }

  Future<(String, Usuario)?> lerSessao() async {
    try {
      final token = await _storage.read(key: _kToken);
      final usuario = await _storage.read(key: _kUsuario);
      if (token == null || usuario == null) return null;
      return (token, Usuario.fromJson(jsonDecode(usuario) as Map<String, dynamic>));
    } catch (_) {
      return null;
    }
  }

  Future<void> limparSessao() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUsuario);
    await _storage.delete(key: _kSetor);
  }

  Future<void> salvarSetor(String id) => _storage.write(key: _kSetor, value: id);

  Future<String?> lerSetor() async {
    try {
      return await _storage.read(key: _kSetor);
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarApiUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _storage.delete(key: _kApiUrl);
    } else {
      await _storage.write(key: _kApiUrl, value: url);
    }
  }

  Future<String?> lerApiUrl() async {
    try {
      return await _storage.read(key: _kApiUrl);
    } catch (_) {
      return null;
    }
  }
}

/// Verifica a expiração do JWT sem validar a assinatura (isso é papel da API).
bool tokenExpirado(String token, {DateTime? agora}) {
  try {
    final partes = token.split('.');
    if (partes.length != 3) return true;
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))));
    final exp = (payload as Map<String, dynamic>)['exp'];
    if (exp is! num) return false;
    final expira = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return !(agora ?? DateTime.now()).isBefore(expira);
  } catch (_) {
    return true;
  }
}
