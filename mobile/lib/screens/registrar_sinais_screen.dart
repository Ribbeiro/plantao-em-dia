import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paciente.dart';
import '../models/sinais_vitais.dart';
import '../providers/providers.dart';
import '../utils/formatos.dart';
import '../widgets/estado_async.dart';
import '../widgets/indicadores.dart';
import '../widgets/marca.dart';

/// Tela 4a – Registro rápido de sinais vitais (POST /pacientes/:id/sinais-vitais).
class RegistrarSinaisScreen extends ConsumerStatefulWidget {
  const RegistrarSinaisScreen({super.key, required this.paciente});

  final PacienteResumo paciente;

  @override
  ConsumerState<RegistrarSinaisScreen> createState() => _RegistrarSinaisScreenState();
}

class _Campo {
  _Campo(this.rotulo, this.unidade, this.min, this.max, {this.decimal = false});

  final String rotulo;
  final String unidade;
  final num min;
  final num max;
  final bool decimal;
  final controle = TextEditingController();
}

class _RegistrarSinaisScreenState extends ConsumerState<RegistrarSinaisScreen> {
  final _form = GlobalKey<FormState>();
  final _pas = _Campo('PA sistólica', 'mmHg', 40, 300);
  final _pad = _Campo('PA diastólica', 'mmHg', 20, 200);
  final _fc = _Campo('Freq. cardíaca', 'bpm', 20, 250);
  final _fr = _Campo('Freq. respiratória', 'irpm', 4, 80);
  final _temp = _Campo('Temperatura', '°C', 30, 45, decimal: true);
  final _sat = _Campo('SatO2', '%', 50, 100);
  final _obs = TextEditingController();
  double _dor = 0;
  bool _salvando = false;

  List<_Campo> get _campos => [_pas, _pad, _fc, _fr, _temp, _sat];

  @override
  void initState() {
    super.initState();
    for (final c in _campos) {
      c.controle.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _campos) {
      c.controle.dispose();
    }
    _obs.dispose();
    super.dispose();
  }

  int? _int(_Campo c) => numeroDigitado(c.controle.text)?.round();

  List<String> get _alertas => alertasSinaisVitais(
    pas: _int(_pas),
    pad: _int(_pad),
    fc: _int(_fc),
    fr: _int(_fr),
    temperatura: numeroDigitado(_temp.controle.text),
    satO2: _int(_sat),
    dor: _dor.round(),
  );

  String? _validar(_Campo c, String? texto) {
    final n = numeroDigitado(texto);
    if (n == null) return 'Obrigatório';
    if (!c.decimal && n != n.roundToDouble()) return 'Número inteiro';
    if (n < c.min || n > c.max) return 'Entre ${c.min} e ${c.max}';
    if (c == _pad) {
      final pas = numeroDigitado(_pas.controle.text);
      if (pas != null && n >= pas) return 'Menor que a sistólica';
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final sv = await ref
          .read(apiProvider)
          .registrarSinais(
            widget.paciente.id,
            pas: _int(_pas)!,
            pad: _int(_pad)!,
            fc: _int(_fc)!,
            fr: _int(_fr)!,
            temperatura: numeroDigitado(_temp.controle.text)!,
            satO2: _int(_sat)!,
            dor: _dor.round(),
            observacao: _obs.text.trim(),
          );
      if (!mounted) return;
      final alertas = sv.alertas;
      avisar(
        context,
        alertas.isEmpty ? 'Sinais vitais registrados' : 'Registrado com alerta: ${alertas.join(', ')}',
        erro: alertas.isNotEmpty,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) avisar(context, e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _campo(_Campo c, {bool alerta = false}) => TextFormField(
    controller: c.controle,
    keyboardType: TextInputType.numberWithOptions(decimal: c.decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(c.decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
      LengthLimitingTextInputFormatter(5),
    ],
    textInputAction: TextInputAction.next,
    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: alerta ? CoresClinicas.alto : null),
    decoration: InputDecoration(
      labelText: c.rotulo,
      suffixText: c.unidade,
      filled: alerta,
      fillColor: alerta ? CoresClinicas.alto.withValues(alpha: 0.08) : null,
      enabledBorder: alerta
          ? const OutlineInputBorder(borderSide: BorderSide(color: CoresClinicas.alto, width: 2))
          : null,
      prefixIcon: alerta ? const Icon(Icons.warning_amber_rounded, color: CoresClinicas.alto) : null,
    ),
    validator: (v) => _validar(c, v),
  );

  @override
  Widget build(BuildContext context) {
    final alertas = _alertas;
    final sat = _int(_sat);
    final pas = _int(_pas);
    final fc = _int(_fc);
    final fr = _int(_fr);
    final temp = numeroDigitado(_temp.controle.text);

    return Scaffold(
      appBar: AppBar(flexibleSpace: const FundoBarraClinica(), title: Text('Sinais vitais · ${widget.paciente.leito}')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.paciente.nome, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _campo(_pas, alerta: pas != null && (pas >= 160 || pas < 90))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/', style: TextStyle(fontSize: 24)),
                ),
                Expanded(child: _campo(_pad)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo(_fc, alerta: fc != null && (fc > 120 || fc < 50))),
                const SizedBox(width: 12),
                Expanded(child: _campo(_fr, alerta: fr != null && fr > 24)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo(_temp, alerta: temp != null && temp >= 37.8)),
                const SizedBox(width: 12),
                Expanded(child: _campo(_sat, alerta: sat != null && sat < 92)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Dor: ${_dor.round()}/10', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _dor,
              min: 0,
              max: 10,
              divisions: 10,
              label: '${_dor.round()}',
              activeColor: _dor >= 7 ? CoresClinicas.alto : (_dor >= 4 ? CoresClinicas.medio : CoresClinicas.ok),
              onChanged: (v) => setState(() => _dor = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _obs,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Observação (opcional)'),
            ),
            if (alertas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CoresClinicas.alto.withValues(alpha: 0.1),
                  border: Border.all(color: CoresClinicas.alto),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: CoresClinicas.alto),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Atenção: ${alertas.join(' · ')}.\nConfira o valor e comunique a equipe se confirmado.',
                        style: const TextStyle(color: CoresClinicas.alto, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Salvar sinais vitais'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
