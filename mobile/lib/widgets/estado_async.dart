import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exibe os três estados de uma tela que consome a API:
/// carregando, erro (com "Tentar novamente") e vazio.
class EstadoAsync<T> extends StatelessWidget {
  const EstadoAsync({
    super.key,
    required this.valor,
    required this.aoTentarNovamente,
    required this.construtor,
    this.estaVazio,
    this.mensagemVazio = 'Nada por aqui.',
    this.iconeVazio = Icons.inbox_outlined,
  });

  final AsyncValue<T> valor;
  final VoidCallback aoTentarNovamente;
  final Widget Function(T dados) construtor;
  final bool Function(T dados)? estaVazio;
  final String mensagemVazio;
  final IconData iconeVazio;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      skipLoadingOnRefresh: true,
      loading: () => const Carregando(),
      error: (erro, _) => MensagemErro(erro: erro, aoTentarNovamente: aoTentarNovamente),
      data: (dados) {
        if (estaVazio?.call(dados) ?? false) {
          return MensagemVazia(mensagem: mensagemVazio, icone: iconeVazio, aoAtualizar: aoTentarNovamente);
        }
        return construtor(dados);
      },
    );
  }
}

class Carregando extends StatelessWidget {
  const Carregando({super.key, this.texto = 'Carregando...'});

  final String texto;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(texto, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class MensagemErro extends StatelessWidget {
  const MensagemErro({super.key, required this.erro, required this.aoTentarNovamente});

  final Object erro;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: cores.error),
            const SizedBox(height: 16),
            Text('Algo deu errado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(erro.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: aoTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class MensagemVazia extends StatelessWidget {
  const MensagemVazia({super.key, required this.mensagem, this.icone = Icons.inbox_outlined, this.aoAtualizar});

  final String mensagem;
  final IconData icone;
  final VoidCallback? aoAtualizar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: cores.outline),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (aoAtualizar != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: aoAtualizar,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mostra uma mensagem rápida na parte de baixo da tela.
void avisar(BuildContext context, String texto, {bool erro = false}) {
  final cores = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: erro ? cores.error : null, behavior: SnackBarBehavior.floating),
    );
}
