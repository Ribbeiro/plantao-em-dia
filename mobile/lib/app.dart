import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/selecionar_setor_screen.dart';
import 'theme/tema.dart';

final navegadorKey = GlobalKey<NavigatorState>();

class PlantaoEmDiaApp extends ConsumerWidget {
  const PlantaoEmDiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);

    // Ao sair (ou expirar o token), fecha as telas abertas por cima da principal.
    ref.listen(sessaoProvider, (anterior, atual) {
      final mudouUsuario = anterior?.logado != atual.logado;
      final mudouSetor = anterior?.setor?.id != atual.setor?.id;
      if (mudouUsuario || mudouSetor) navegadorKey.currentState?.popUntil((r) => r.isFirst);
    });

    final Widget inicial;
    if (!sessao.logado) {
      inicial = const LoginScreen();
    } else if (sessao.setor == null) {
      inicial = const SelecionarSetorScreen();
    } else {
      inicial = const HomeScreen();
    }

    return MaterialApp(
      title: 'Plantão em Dia',
      debugShowCheckedModeBanner: false,
      navigatorKey: navegadorKey,
      theme: temaPlantao(Brightness.light),
      darkTheme: temaPlantao(Brightness.dark),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey('${sessao.logado}-${sessao.setor?.id}'), child: inicial),
      ),
    );
  }
}
