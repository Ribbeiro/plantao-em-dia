import 'package:flutter/foundation.dart';

/// URL base da API.
///
/// Ordem de prioridade:
/// 1. `--dart-define=API_URL=http://192.168.0.10:3000` na hora de rodar;
/// 2. URL salva pelo usuário em "Configurar servidor" na tela de login;
/// 3. padrão por plataforma: o emulador Android enxerga o computador em 10.0.2.2,
///    já o navegador e o simulador iOS usam localhost.
class ApiConfig {
  static const String _definida = String.fromEnvironment('API_URL');

  static String get padrao {
    if (_definida.isNotEmpty) return _definida;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static const Duration timeout = Duration(seconds: 10);
}
