import 'package:flutter/material.dart';

import '../models/intercorrencia.dart';
import '../models/paciente.dart';

/// Cores fixas para risco/gravidade, legíveis no tema claro e escuro.
class CoresClinicas {
  static const alto = Color(0xFFC62828);
  static const medio = Color(0xFFEF6C00);
  static const baixo = Color(0xFF2E7D32);
  static const atrasada = Color(0xFFC62828);
  static const ok = Color(0xFF2E7D32);

  static Color risco(Risco r) => switch (r) {
    Risco.alto => alto,
    Risco.medio => medio,
    Risco.baixo => baixo,
  };

  static Color gravidade(Gravidade g) => switch (g) {
    Gravidade.grave => alto,
    Gravidade.moderada => medio,
    Gravidade.leve => baixo,
  };
}

class Etiqueta extends StatelessWidget {
  const Etiqueta({super.key, required this.texto, required this.cor, this.icone, this.solida = false});

  final String texto;
  final Color cor;
  final IconData? icone;
  final bool solida;

  @override
  Widget build(BuildContext context) {
    final frente = solida ? Colors.white : cor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: solida ? cor : cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: solida ? null : Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[Icon(icone, size: 14, color: frente), const SizedBox(width: 4)],
          Text(
            texto,
            style: TextStyle(color: frente, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class EtiquetaRisco extends StatelessWidget {
  const EtiquetaRisco(this.risco, {super.key});

  final Risco risco;

  @override
  Widget build(BuildContext context) => Etiqueta(
    texto: 'Risco ${risco.rotulo.toLowerCase()}',
    cor: CoresClinicas.risco(risco),
    icone: Icons.shield_outlined,
  );
}

class EtiquetaAlergia extends StatelessWidget {
  const EtiquetaAlergia(this.alergias, {super.key, this.compacta = false});

  final List<String> alergias;
  final bool compacta;

  @override
  Widget build(BuildContext context) => Etiqueta(
    texto: compacta ? 'Alergia' : 'Alergia: ${alergias.join(', ')}',
    cor: CoresClinicas.alto,
    icone: Icons.warning_amber_rounded,
    solida: true,
  );
}

/// Contador redondo (ex.: pendências no card do leito).
class Contador extends StatelessWidget {
  const Contador({super.key, required this.valor, this.cor, this.tooltip});

  final int valor;
  final Color? cor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Theme.of(context).colorScheme.primary;
    final badge = Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
      // Center com fatores 1 mantém o badge do tamanho do texto (não estica na linha).
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          '$valor',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
    return tooltip == null ? badge : Tooltip(message: tooltip!, child: badge);
  }
}

class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.icone, this.cor, this.trailing});

  final String texto;
  final IconData? icone;
  final Color? cor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          if (icone != null) ...[Icon(icone, color: c, size: 20), const SizedBox(width: 8)],
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: c, fontWeight: FontWeight.bold),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
