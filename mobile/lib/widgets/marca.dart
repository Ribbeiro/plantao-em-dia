import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// Logo do app: quadrado arredondado azul com cruz médica branca
/// e uma linha de batimento cardíaco (ECG) em turquesa.
class LogoPlantao extends StatelessWidget {
  const LogoPlantao({super.key, this.tamanho = 72, this.contorno = false});

  final double tamanho;

  /// Contorno branco, para usar sobre fundo azul.
  final bool contorno;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: tamanho,
    child: CustomPaint(painter: _LogoPainter(contorno: contorno)),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.contorno});

  final bool contorno;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final caixa = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.24));
    canvas.drawRRect(caixa, Paint()..shader = CoresMarca.gradiente.createShader(Offset.zero & size));
    if (contorno) {
      canvas.drawRRect(
        caixa.deflate(s * 0.015),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..color = Colors.white.withValues(alpha: 0.6),
      );
    }

    // Cruz médica.
    final braco = s * 0.17;
    final comprimento = s * 0.56;
    final c = s / 2;
    final cruz = Paint()..color = Colors.white;
    final r = Radius.circular(s * 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c, c), width: braco, height: comprimento), r),
      cruz,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c, c), width: comprimento, height: braco), r),
      cruz,
    );

    // Linha de ECG atravessando a cruz.
    final y = c;
    final ecg = Path()
      ..moveTo(s * 0.10, y)
      ..lineTo(s * 0.36, y)
      ..lineTo(s * 0.43, y - s * 0.07)
      ..lineTo(s * 0.50, y + s * 0.20)
      ..lineTo(s * 0.57, y - s * 0.26)
      ..lineTo(s * 0.64, y)
      ..lineTo(s * 0.90, y);
    canvas.drawPath(
      ecg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.055
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = CoresMarca.turquesa,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.contorno != contorno;
}

/// Linha de batimento cardíaco repetida na largura disponível (decoração de fundo).
class LinhaEcg extends StatelessWidget {
  const LinhaEcg({super.key, this.cor = Colors.white, this.altura = 48, this.espessura = 2});

  final Color cor;
  final double altura;
  final double espessura;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: altura,
    width: double.infinity,
    child: CustomPaint(painter: _EcgPainter(cor, espessura)),
  );
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(this.cor, this.espessura);

  final Color cor;
  final double espessura;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final meio = h * 0.6;
    const periodo = 140.0;
    final path = Path()..moveTo(0, meio);
    for (double x = 0; x < size.width; x += periodo) {
      path
        ..lineTo(x + 40, meio)
        ..quadraticBezierTo(x + 48, meio - h * 0.12, x + 56, meio)
        ..lineTo(x + 64, meio)
        ..lineTo(x + 70, meio + h * 0.15)
        ..lineTo(x + 78, meio - h * 0.55)
        ..lineTo(x + 86, meio + h * 0.3)
        ..lineTo(x + 92, meio)
        ..lineTo(x + 104, meio)
        ..quadraticBezierTo(x + 116, meio - h * 0.18, x + 128, meio)
        ..lineTo(x + periodo, meio);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeJoin = StrokeJoin.round
        ..color = cor,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.cor != cor || old.espessura != espessura;
}

/// Fundo em gradiente azul com ECG discreto – usado no AppBar (flexibleSpace).
class FundoBarraClinica extends StatelessWidget {
  const FundoBarraClinica({super.key});

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(gradient: CoresMarca.gradiente),
      alignment: Alignment.bottomCenter,
      child: LinhaEcg(cor: Colors.white.withValues(alpha: 0.12), altura: 40, espessura: 1.5),
    );
  }
}
