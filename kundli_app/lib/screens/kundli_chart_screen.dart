import 'package:flutter/material.dart';

class KundliChartScreen extends StatelessWidget {
  const KundliChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("North Indian Kundli"),
      ),
      body: Center(
        child: Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(width: 2),
          ),
          child: CustomPaint(
            painter: KundliPainter(),
            child: const Center(
              child: Text(
                "Lagna",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KundliPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width, size.height / 2),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height / 2),
      Offset(size.width / 2, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(0, size.height / 2),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width / 2, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}