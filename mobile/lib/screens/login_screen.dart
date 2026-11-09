import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/api_config.dart';
import '../theme/tema.dart';
import '../widgets/estado_async.dart';
import '../widgets/marca.dart';

/// Tela 1 – Login (POST /auth/login).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultarSenha = true;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(sessaoProvider.notifier).entrar(_usuario.text.trim(), _senha.text);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _configurarServidor() async {
    final atual = ref.read(apiUrlProvider);
    final controle = TextEditingController(text: atual);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor da API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controle,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL base', hintText: 'http://10.0.2.2:3000'),
            ),
            const SizedBox(height: 12),
            Text(
              'Emulador Android: http://10.0.2.2:3000\n'
              'Celular físico: http://<IP do computador>:3000\n'
              'Padrão deste aparelho: ${ApiConfig.padrao}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Usar padrão')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controle.text), child: const Text('Salvar')),
        ],
      ),
    );
    controle.dispose();
    if (resultado == null) return;
    await ref.read(apiUrlProvider.notifier).definir(resultado);
    if (mounted) avisar(context, 'Servidor: ${ref.read(apiUrlProvider)}');
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final mensagemSessao = ref.watch(sessaoProvider.select((s) => s.mensagem));
    final erro = _erro ?? mensagemSessao;

    final escuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho clínico: gradiente azul, logo com cruz médica e linha de ECG.
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: CoresMarca.gradiente),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 36,
                      child: LinhaEcg(cor: Colors.white.withValues(alpha: 0.18), altura: 70, espessura: 2),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        tooltip: 'Configurar servidor',
                        color: Colors.white,
                        icon: const Icon(Icons.settings_ethernet),
                        onPressed: _configurarServidor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 72),
                      child: Column(
                        children: [
                          const LogoPlantao(tamanho: 84, contorno: true),
                          const SizedBox(height: 16),
                          Text(
                            'Plantão em Dia',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Passagem de plantão segura para enfermagem e equipe médica',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    elevation: escuro ? 0 : 6,
                    shadowColor: CoresMarca.azulEscuro.withValues(alpha: 0.25),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Form(
                        key: _form,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, color: cores.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Acesso do profissional',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _usuario,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Usuário',
                                  prefixIcon: Icon(Icons.person_outline),
                                  hintText: 'ex.: ana.enfermeira',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o usuário' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _senha,
                                obscureText: _ocultarSenha,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _entrar(),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                                    icon: Icon(
                                      _ocultarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                              ),
                              if (erro != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cores.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: cores.onErrorContainer),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(erro, style: TextStyle(color: cores.onErrorContainer)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _enviando ? null : _entrar,
                                icon: _enviando
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: const Text('Entrar no plantão'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: cores.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Acesso individual protegido por login e token seguro',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cores.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ambiente acadêmico: todos os pacientes são fictícios.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cores.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
