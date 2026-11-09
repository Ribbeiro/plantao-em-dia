import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantao_em_dia/models/intercorrencia.dart';
import 'package:plantao_em_dia/models/movimentacao.dart';
import 'package:plantao_em_dia/models/paciente.dart';
import 'package:plantao_em_dia/models/pendencia.dart';
import 'package:plantao_em_dia/models/plantao.dart';
import 'package:plantao_em_dia/models/setor.dart';
import 'package:plantao_em_dia/models/sinais_vitais.dart';
import 'package:plantao_em_dia/models/usuario.dart';
import 'package:plantao_em_dia/services/armazenamento.dart';

/// JSON no mesmo formato devolvido pela API (dados fictícios).
const _pacienteJson = '''
{
  "id": "cm_p1", "setorId": "cm", "leito": "CM-01", "nome": "Aurora Vilela Prado",
  "idade": 74, "sexo": "F", "diagnostico": "Pneumonia comunitária",
  "alergias": ["Dipirona"], "risco": "alto", "medicacoesAtrasadas": 1, "pendencias": 3,
  "alertas": ["SatO2 baixa (90%)"],
  "historico": "Hipertensa.", "dispositivos": ["AVP MSE"], "dieta": "Branda",
  "dataInternacao": "2026-11-05T10:00:00.000Z",
  "sinaisVitais": [
    {"id": "sv_1", "pacienteId": "cm_p1", "pas": 120, "pad": 80, "fc": 88, "fr": 18,
     "temperatura": 37.9, "satO2": 90, "dor": 2, "observacao": "", "registradoEm": "2026-11-08T12:00:00.000Z",
     "responsavel": "Ana Ribeiro"}
  ],
  "medicacoes": [
    {"id": "med_1", "pacienteId": "cm_p1", "nome": "Ceftriaxona", "dose": "1 g", "via": "EV",
     "horario": "2026-11-08T08:00:00.000Z", "status": "pendente", "administradaEm": null,
     "responsavel": null, "atrasada": true},
    {"id": "med_2", "pacienteId": "cm_p1", "nome": "Omeprazol", "dose": "40 mg", "via": "EV",
     "horario": "2026-11-08T06:00:00.000Z", "status": "administrada",
     "administradaEm": "2026-11-08T06:10:00.000Z", "responsavel": "Bruno Carvalho", "atrasada": false}
  ],
  "intercorrencias": [
    {"id": "int_1", "pacienteId": "cm_p1", "descricao": "Queda de saturação", "gravidade": "moderada",
     "horario": "2026-11-08T11:00:00.000Z", "responsavel": "Ana Ribeiro"}
  ],
  "pendenciasLista": [
    {"id": "pend_1", "pacienteId": "cm_p1", "tipo": "exame", "descricao": "Raio-X de tórax",
     "prazo": "2026-11-08T15:00:00.000Z", "status": "pendente"}
  ]
}
''';

void main() {
  group('PacienteDetalhe.fromJson', () {
    final p = PacienteDetalhe.fromJson(jsonDecode(_pacienteJson) as Map<String, dynamic>);

    test('lê os dados do leito e do risco', () {
      expect(p.leito, 'CM-01');
      expect(p.risco, Risco.alto);
      expect(p.temAlergia, isTrue);
      expect(p.alergias, ['Dipirona']);
      expect(p.pendencias, 3);
      expect(p.dataInternacao.isUtc, isFalse, reason: 'datas são convertidas para o horário local');
    });

    test('lê sinais vitais, medicações, intercorrências e pendências', () {
      expect(p.ultimosSinais!.temperatura, 37.9);
      expect(p.ultimosSinais!.alertas, contains('SatO2 baixa (90%)'));
      expect(p.medicacoes.first.atrasada, isTrue);
      expect(p.medicacoes.last.administrada, isTrue);
      expect(p.medicacoes.last.responsavel, 'Bruno Carvalho');
      expect(p.intercorrencias.single.gravidade, Gravidade.moderada);
      expect(p.pendenciasLista.single.tipoRotulo, 'Exame');
    });
  });

  test('PacienteResumo tolera campos ausentes', () {
    final p = PacienteResumo.fromJson({'id': 'x', 'leito': 'PED-02', 'risco': 'desconhecido'});
    expect(p.risco, Risco.baixo);
    expect(p.alergias, isEmpty);
    expect(p.pendencias, 0);
    expect(p.nome, '');
  });

  test('Plantao.fromJson lê SBAR, totais e confirmação', () {
    final plantao = Plantao.fromJson({
      'id': 'plt_1',
      'setorId': 'cm',
      'setorNome': 'Clínica Médica',
      'responsavel': {'id': 'u1', 'nome': 'Ana Ribeiro', 'cargo': 'Enfermeira'},
      'inicio': '2026-11-08T07:00:00.000Z',
      'fim': '2026-11-08T19:00:00.000Z',
      'observacoes': '',
      'totais': {'pacientes': 11, 'medicacoesAtrasadas': 2, 'pendencias': 5, 'comAlerta': 1},
      'resumo': [
        {
          'pacienteId': 'cm_p1',
          'nome': 'Aurora',
          'leito': 'CM-01',
          'risco': 'medio',
          'alergias': <String>[],
          'situacao': 'S',
          'breveHistorico': 'B',
          'avaliacao': 'A',
          'recomendacao': 'R',
          'alertas': ['febre'],
          'medicacoesAtrasadas': 0,
          'pendenciasAbertas': 1,
        },
      ],
      'confirmacao': {
        'usuarioId': 'u2',
        'nome': 'Bruno Carvalho',
        'cargo': 'Técnico de enfermagem',
        'confirmadoEm': '2026-11-08T19:05:00.000Z',
      },
    });
    expect(plantao.totais.pacientes, 11);
    expect(plantao.confirmado, isTrue);
    expect(plantao.confirmacao!.profissional.id, 'u2');
    expect(plantao.resumo.single.precisaAtencao, isTrue, reason: 'tem alerta');
    expect(plantao.resumo.single.texto, contains('S: S'));
  });

  test('Plantao sem confirmação e sem resumo (listagem do histórico)', () {
    final p = Plantao.fromJson({'id': 'plt_2', 'inicio': '2026-11-08T07:00:00Z', 'fim': '2026-11-08T19:00:00Z'});
    expect(p.confirmado, isFalse);
    expect(p.resumo, isEmpty);
    expect(p.totais.pacientes, 0);
  });

  test('PendenciasSetor agrupa medicações com referência ao paciente', () {
    final ps = PendenciasSetor.fromJson({
      'total': 2,
      'medicacoesAtrasadas': [
        {
          'id': 'med_9',
          'nome': 'Dipirona',
          'dose': '1 g',
          'via': 'EV',
          'horario': '2026-11-08T10:00:00Z',
          'status': 'pendente',
          'atrasada': true,
          'paciente': {'id': 'cm_p2', 'nome': 'Benedito', 'leito': 'CM-02', 'risco': 'alto'},
        },
      ],
      'exames': [
        {
          'id': 'pend_1',
          'tipo': 'exame',
          'descricao': 'Hemograma',
          'prazo': '2026-11-08T10:00:00Z',
          'status': 'pendente',
          'vencida': true,
        },
      ],
      'procedimentos': <dynamic>[],
      'retornos': <dynamic>[],
    });
    expect(ps.vazio, isFalse);
    expect(ps.medicacoesAtrasadas.single.paciente!.leito, 'CM-02');
    expect(ps.exames.single.vencida, isTrue);
  });

  test('Usuario e Setor fazem ida e volta em JSON', () {
    final u = Usuario.fromJson({
      'id': 'u3',
      'usuario': 'carla.medica',
      'nome': 'Dra. Carla Nogueira',
      'cargo': 'Médica',
      'setorId': 'ped',
      'setor': {'id': 'ped', 'nome': 'Pediatria', 'leitos': 8},
    });
    final copia = Usuario.fromJson(jsonDecode(jsonEncode(u.toJson())) as Map<String, dynamic>);
    expect(copia.setor!.nome, 'Pediatria');
    expect(copia.iniciais, 'CN');
    expect(Setor.fromJson({'id': 'cm', 'nome': 'Clínica Médica', 'medicacoesAtrasadas': '3'}).medicacoesAtrasadas, 3);
  });

  group('alertasSinaisVitais', () {
    test('sinais normais não geram alerta', () {
      expect(alertasSinaisVitais(pas: 120, pad: 80, fc: 80, fr: 16, temperatura: 36.5, satO2: 97, dor: 2), isEmpty);
    });

    test('SatO2 < 92% gera alerta visual', () {
      expect(alertasSinaisVitais(satO2: 91), ['SatO2 baixa (91%)']);
      expect(alertasSinaisVitais(satO2: 92), isEmpty);
    });

    test('vários alertas ao mesmo tempo', () {
      final a = alertasSinaisVitais(pas: 170, pad: 100, fc: 130, temperatura: 38.4, fr: 28, dor: 8);
      expect(a.length, 5);
    });
  });

  group('tokenExpirado', () {
    String token(int exp) {
      final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': 'u1', 'exp': exp}))).replaceAll('=', '');
      return 'eyJhbGciOiJIUzI1NiJ9.$payload.assinatura';
    }

    test('token válido e expirado', () {
      final agora = DateTime(2026, 11, 8, 12);
      final seg = agora.millisecondsSinceEpoch ~/ 1000;
      expect(tokenExpirado(token(seg + 3600), agora: agora), isFalse);
      expect(tokenExpirado(token(seg - 1), agora: agora), isTrue);
    });

    test('token malformado é tratado como expirado', () {
      expect(tokenExpirado('abc'), isTrue);
    });
  });
  group('Admissão e alta', () {
    test('Leito, saída do paciente e movimentações do turno', () {
      final leitos = [
        {
          'leito': 'PED-09',
          'ocupado': true,
          'paciente': {'id': 'p9', 'nome': 'Fulano'},
        },
        {'leito': 'PED-10', 'ocupado': false, 'paciente': null},
      ].map(Leito.fromJson).toList();
      expect(leitos.first.pacienteNome, 'Fulano');
      expect(leitos.last.ocupado, isFalse);

      final detalhe = PacienteDetalhe.fromJson({
        'id': 'p1',
        'nome': 'Teste',
        'leito': 'CM-01',
        'dataInternacao': '2026-11-08T10:00:00Z',
        'alta': {'tipo': 'transferencia', 'destino': 'UTI', 'em': '2026-11-09T02:00:00Z', 'por': 'Ana'},
      });
      expect(detalhe.internado, isFalse);
      expect(detalhe.saida!.tipo, TipoSaida.transferencia);
      expect(detalhe.saida!.destino, 'UTI');
      expect(PacienteDetalhe.fromJson({'id': 'p2'}).internado, isTrue);

      final plantao = Plantao.fromJson({
        'id': 'x',
        'movimentacoes': {
          'admissoes': [
            {'leito': 'CM-12', 'nome': 'Novo', 'por': 'Ana', 'em': '2026-11-09T01:00:00Z'},
          ],
          'saidas': [
            {'leito': 'CM-03', 'nome': 'Velho', 'tipo': 'alta', 'por': 'Ana', 'em': '2026-11-09T01:30:00Z'},
          ],
        },
      });
      expect(plantao.movimentacoes.admissoes.single.nome, 'Novo');
      expect(plantao.movimentacoes.saidas.single.tipo, TipoSaida.alta);
      expect(Plantao.fromJson({'id': 'y'}).movimentacoes.vazio, isTrue);
    });
  });
}
