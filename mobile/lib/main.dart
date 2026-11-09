import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  // Sem nova tentativa automática: a tela mostra o erro e o botão "Tentar novamente".
  final container = ProviderContainer(retry: (_, _) => null);
  await container.read(apiUrlProvider.notifier).carregar();
  await container.read(sessaoProvider.notifier).restaurar();

  runApp(UncontrolledProviderScope(container: container, child: const PlantaoEmDiaApp()));
}
