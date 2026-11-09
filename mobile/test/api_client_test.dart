import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantao_em_dia/services/api_client.dart';

void main() {
  RequestOptions opcoes([String caminho = '/setores']) => RequestOptions(path: caminho);

  test('erro da API em JSON vira mensagem com detalhes', () {
    final e = traduzirErro(DioException(
      requestOptions: opcoes(),
      response: Response(
        requestOptions: opcoes(),
        statusCode: 400,
        data: {
          'erro': 'Dados inválidos',
          'detalhes': ['SatO2 deve ser no máximo 100'],
        },
      ),
    ));
    expect(e.status, 400);
    expect(e.mensagem, 'Dados inválidos');
    expect(e.toString(), contains('SatO2 deve ser no máximo 100'));
  });

  test('sem resposta do servidor vira mensagem de conexão', () {
    final e = traduzirErro(DioException(requestOptions: opcoes(), type: DioExceptionType.connectionError));
    expect(e.semConexao, isTrue);
    expect(e.mensagem, contains('Não foi possível conectar'));
  });

  test('timeout tem mensagem própria', () {
    final e = traduzirErro(DioException(requestOptions: opcoes(), type: DioExceptionType.receiveTimeout));
    expect(e.mensagem, contains('demorou'));
  });

  test('resposta sem corpo JSON usa o código HTTP', () {
    final e = traduzirErro(DioException(
      requestOptions: opcoes(),
      response: Response(requestOptions: opcoes(), statusCode: 502, data: '<html>'),
    ));
    expect(e.mensagem, contains('502'));
  });
}
