import 'package:dio/dio.dart';

import 'api_config.dart';

/// Erro amigável exibido nas telas.
class ApiException implements Exception {
  const ApiException(this.mensagem, {this.status, this.detalhes = const []});

  final String mensagem;
  final int? status;
  final List<String> detalhes;

  bool get semConexao => status == null;

  @override
  String toString() => detalhes.isEmpty ? mensagem : '$mensagem\n• ${detalhes.join('\n• ')}';
}

/// Cliente HTTP com interceptor que injeta o token e traduz os erros.
class ApiClient {
  ApiClient({required String baseUrl, required this.lerToken, required this.aoExpirarSessao, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: ApiConfig.timeout,
              receiveTimeout: ApiConfig.timeout,
              sendTimeout: ApiConfig.timeout,
              contentType: 'application/json',
              responseType: ResponseType.json,
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = lerToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (erro, handler) {
          final status = erro.response?.statusCode;
          final ehLogin = erro.requestOptions.path.contains('/auth/login');
          if (status == 401 && !ehLogin) aoExpirarSessao();
          handler.reject(
            DioException(
              requestOptions: erro.requestOptions,
              response: erro.response,
              type: erro.type,
              error: traduzirErro(erro),
            ),
          );
        },
      ),
    );
  }

  final Dio dio;
  final String? Function() lerToken;
  final void Function() aoExpirarSessao;

  String get baseUrl => dio.options.baseUrl;
  set baseUrl(String url) => dio.options.baseUrl = url;

  Future<T> get<T>(String caminho, {Map<String, dynamic>? query}) =>
      _executar(() => dio.get<T>(caminho, queryParameters: query));

  Future<T> post<T>(String caminho, [Object? corpo]) =>
      _executar(() => dio.post<T>(caminho, data: corpo ?? <String, dynamic>{}));

  Future<T> patch<T>(String caminho, [Object? corpo]) =>
      _executar(() => dio.patch<T>(caminho, data: corpo ?? <String, dynamic>{}));

  Future<T> _executar<T>(Future<Response<T>> Function() chamada) async {
    try {
      final resp = await chamada();
      return resp.data as T;
    } on DioException catch (e) {
      final erro = e.error;
      throw erro is ApiException ? erro : traduzirErro(e);
    }
  }
}

/// Converte qualquer falha do dio em uma mensagem em português.
ApiException traduzirErro(DioException e) {
  final resp = e.response;
  if (resp != null) {
    final dados = resp.data;
    if (dados is Map && dados['erro'] is String) {
      return ApiException(
        dados['erro'] as String,
        status: resp.statusCode,
        detalhes: dados['detalhes'] is List ? (dados['detalhes'] as List).whereType<String>().toList() : const [],
      );
    }
    return ApiException('Erro ${resp.statusCode} ao falar com o servidor', status: resp.statusCode);
  }
  return switch (e.type) {
    DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout =>
      const ApiException('O servidor demorou para responder. Verifique a conexão e tente novamente.'),
    _ => const ApiException(
      'Não foi possível conectar à API. Confira se o backend está rodando e se a URL do servidor está correta.',
    ),
  };
}
