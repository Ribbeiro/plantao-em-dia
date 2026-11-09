import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantao_em_dia/models/paciente.dart';
import 'package:plantao_em_dia/screens/pacientes_screen.dart';
import 'package:plantao_em_dia/services/api_client.dart';
import 'package:plantao_em_dia/widgets/estado_async.dart';

Widget _app(Widget filho) => ProviderScope(child: MaterialApp(home: Scaffold(body: filho)));

void main() {
  testWidgets('EstadoAsync mostra erro com "Tentar novamente"', (tester) async {
    var tentativas = 0;
    await tester.pumpWidget(_app(EstadoAsync<int>(
      valor: const AsyncValue.error(ApiException('Sem conexão'), StackTrace.empty),
      aoTentarNovamente: () => tentativas++,
      construtor: (_) => const SizedBox(),
    )));
    expect(find.text('Sem conexão'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(tentativas, 1);
  });

  testWidgets('EstadoAsync mostra estado vazio', (tester) async {
    await tester.pumpWidget(_app(EstadoAsync<List<int>>(
      valor: const AsyncValue.data([]),
      aoTentarNovamente: () {},
      estaVazio: (l) => l.isEmpty,
      mensagemVazio: 'Nenhum paciente',
      construtor: (_) => const SizedBox(),
    )));
    expect(find.text('Nenhum paciente'), findsOneWidget);
  });

  testWidgets('CardPaciente exibe leito, alergia e pendências', (tester) async {
    const p = PacienteResumo(
      id: 'cm_p1',
      setorId: 'cm',
      leito: 'CM-07',
      nome: 'Glória Antunes Rocha',
      idade: 66,
      sexo: 'F',
      diagnostico: 'DPOC exacerbado',
      alergias: ['AAS'],
      risco: Risco.alto,
      medicacoesAtrasadas: 2,
      pendencias: 3,
      alertas: [],
    );
    await tester.pumpWidget(_app(const CardPaciente(paciente: p)));
    expect(find.text('07'), findsOneWidget);
    expect(find.text('Glória Antunes Rocha'), findsOneWidget);
    expect(find.text('Alergia: AAS'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('2 medicação(ões) atrasada(s)'), findsOneWidget);
  });
}
