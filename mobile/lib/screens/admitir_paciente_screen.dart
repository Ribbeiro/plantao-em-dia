import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movimentacao.dart';
import '../models/paciente.dart';
import '../providers/providers.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import '../widgets/marca.dart';

/// Admissão (entrada) de paciente em um leito livre do setor (POST /setores/:id/pacientes).
class AdmitirPacienteScreen extends ConsumerStatefulWidget {
  const AdmitirPacienteScreen({super.key, required this.setorId, required this.setorNome});

  final String setorId;
  final String setorNome;

  @override
  ConsumerState<AdmitirPacienteScreen> createState() => _AdmitirPacienteScreenState();
}

class _AdmitirPacienteScreenState extends ConsumerState<AdmitirPacienteScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _idade = TextEditingController();
  final _diagnostico = TextEditingController();
  final _alergias = TextEditingController();
  final _dieta = TextEditingController();
  final _historico = TextEditingController();
  String _sexo = 'F';
  Risco _risco = Risco.medio;
  String? _leito;
  final Set<String> _dispositivos = {};
  bool _semAlergias = false;
  bool _salvando = false;

  static const _alergiasComuns = ['Dipirona', 'Penicilina', 'AAS', 'Látex', 'Iodo', 'Sulfa'];
  static const _dispositivosComuns = [
    'Acesso venoso periférico',
    'Sonda vesical',
    'Sonda nasoenteral',
    'Cateter de O2',
  ];

  @override
  void dispose() {
    for (final c in [_nome, _idade, _diagnostico, _alergias, _dieta, _historico]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _listaAlergias =>
      _alergias.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

  void _alternarAlergia(String a) {
    final atual = _listaAlergias;
    atual.contains(a) ? atual.remove(a) : atual.add(a);
    setState(() {
      _semAlergias = false;
      _alergias.text = atual.join(', ');
    });
  }

  Future<void> _salvar() async {
    final formOk = _form.currentState!.validate();
    if (_leito == null) {
      avisar(context, 'Escolha um leito livre', erro: true);
      return;
    }
    if (!_semAlergias && _listaAlergias.isEmpty) {
      avisar(context, 'Informe as alergias ou marque "Sem alergias conhecidas"', erro: true);
      return;
    }
    if (!formOk) return;
    setState(() => _salvando = true);
    try {
      final p = await ref
          .read(apiProvider)
          .admitirPaciente(
            widget.setorId,
            nome: _nome.text.trim(),
            idade: int.parse(_idade.text.trim()),
            sexo: _sexo,
            leito: _leito!,
            diagnostico: _diagnostico.text.trim(),
            risco: _risco,
            alergias: _semAlergias ? const [] : _listaAlergias,
            dispositivos: _dispositivos.toList(),
            dieta: _dieta.text.trim(),
            historico: _historico.text.trim(),
          );
      if (!mounted) return;
      atualizarDadosDoSetor(ref, widget.setorId);
      avisar(context, '${p.nome} admitido(a) no leito ${p.leito}');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
      // O leito pode ter sido ocupado por outro profissional: recarrega o mapa.
      ref.invalidate(leitosProvider(widget.setorId));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final leitos = ref.watch(leitosProvider(widget.setorId));

    return Scaffold(
      appBar: AppBar(flexibleSpace: const FundoBarraClinica(), title: const Text('Admitir paciente')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(widget.setorNome, style: tema.textTheme.titleMedium?.copyWith(color: tema.colorScheme.primary)),
            const TituloSecao('Leito', icone: Icons.bed_outlined),
            leitos.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Carregando(texto: 'Carregando leitos...'),
              ),
              error: (e, _) => SizedBox(
                height: 200,
                child: MensagemErro(erro: e, aoTentarNovamente: () => ref.invalidate(leitosProvider(widget.setorId))),
              ),
              data: (lista) =>
                  _MapaLeitos(leitos: lista, selecionado: _leito, aoEscolher: (l) => setState(() => _leito = l)),
            ),
            const TituloSecao('Identificação', icone: Icons.badge_outlined),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().split(' ').where((p) => p.isNotEmpty).length < 2)
                  ? 'Informe nome e sobrenome'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _idade,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                    decoration: const InputDecoration(labelText: 'Idade', suffixText: 'anos'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n > 120) ? 'Inválida' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'F', label: Text('Feminino')),
                      ButtonSegment(value: 'M', label: Text('Masculino')),
                    ],
                    selected: {_sexo},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _sexo = s.first),
                  ),
                ),
              ],
            ),
            const TituloSecao('Quadro clínico', icone: Icons.medical_information_outlined),
            TextFormField(
              controller: _diagnostico,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Diagnóstico / motivo da internação'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Informe o diagnóstico' : null,
            ),
            Text('Risco', style: tema.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<Risco>(
              segments: [
                for (final r in Risco.values)
                  ButtonSegment(
                    value: r,
                    label: Text(r.rotulo),
                    icon: Icon(Icons.circle, size: 12, color: CoresClinicas.risco(r)),
                  ),
              ],
              selected: {_risco},
              onSelectionChanged: (s) => setState(() => _risco = s.first),
            ),
            const TituloSecao('Alergias', icone: Icons.warning_amber_rounded, cor: CoresClinicas.alto),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _semAlergias,
              title: const Text('Sem alergias conhecidas'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() {
                _semAlergias = v ?? false;
                if (_semAlergias) _alergias.clear();
              }),
            ),
            if (!_semAlergias) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final a in _alergiasComuns)
                    FilterChip(
                      label: Text(a),
                      selected: _listaAlergias.contains(a),
                      selectedColor: CoresClinicas.alto.withValues(alpha: 0.15),
                      onSelected: (_) => _alternarAlergia(a),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alergias,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Alergias (separe por vírgula)',
                  hintText: 'ex.: Dipirona, Látex',
                ),
              ),
            ],
            const TituloSecao('Dispositivos e cuidados', icone: Icons.cable),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final d in _dispositivosComuns)
                  FilterChip(
                    label: Text(d),
                    selected: _dispositivos.contains(d),
                    onSelected: (s) => setState(() => s ? _dispositivos.add(d) : _dispositivos.remove(d)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dieta,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Dieta (opcional)', hintText: 'ex.: livre, branda, jejum'),
            ),
            TextFormField(
              controller: _historico,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Histórico / comorbidades (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ao admitir, o app cria a pendência "aferir sinais vitais de admissão" com prazo de 1 hora.',
              style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_add_alt_1),
                label: Text(_leito == null ? 'Admitir paciente' : 'Admitir no leito $_leito'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grade de leitos: livres selecionáveis, ocupados desabilitados com o nome do paciente.
class _MapaLeitos extends StatelessWidget {
  const _MapaLeitos({required this.leitos, required this.selecionado, required this.aoEscolher});

  final List<Leito> leitos;
  final String? selecionado;
  final ValueChanged<String> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final livres = leitos.where((l) => !l.ocupado).length;
    if (livres == 0) {
      return Card(
        color: CoresClinicas.medio.withValues(alpha: 0.1),
        child: const ListTile(
          leading: Icon(Icons.bed, color: CoresClinicas.medio),
          title: Text('Setor lotado'),
          subtitle: Text('Não há leito livre. Dê alta ou transfira um paciente para liberar um leito.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$livres de ${leitos.length} leitos livres', style: tema.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in leitos)
              Tooltip(
                message: l.ocupado ? 'Ocupado: ${l.pacienteNome ?? ''}' : 'Livre',
                child: ChoiceChip(
                  avatar: Icon(l.ocupado ? Icons.bed : Icons.bed_outlined, size: 18),
                  label: Text(l.leito.split('-').last),
                  selected: selecionado == l.leito,
                  onSelected: l.ocupado ? null : (_) => aoEscolher(l.leito),
                  selectedColor: CoresClinicas.ok.withValues(alpha: 0.2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
