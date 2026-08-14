import 'package:flutter/material.dart';

/// Simple multi-color Google "G" icon without external assets.
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final stroke = size.width * 0.18;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    arcPaint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      -0.4,
      1.6,
      false,
      arcPaint,
    );

    arcPaint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      1.2,
      1.0,
      false,
      arcPaint,
    );

    arcPaint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      2.2,
      0.9,
      false,
      arcPaint,
    );

    arcPaint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      3.1,
      1.0,
      false,
      arcPaint,
    );

    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - stroke * 0.1,
        center.dy - stroke * 0.45,
        radius + stroke * 0.2,
        stroke * 0.9,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
