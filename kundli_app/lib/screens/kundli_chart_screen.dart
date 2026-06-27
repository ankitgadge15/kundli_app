import 'package:flutter/material.dart';
import 'dart:math';
import '../models/kundli_result_model.dart';
import '../models/kundli_input_model.dart';
import '../models/planet.dart';
import '../models/planet_position_model.dart';

class KundliChartScreen extends StatelessWidget {
  final KundliResult kundliResult;
  final KundliInput kundliInput;

  const KundliChartScreen({
    super.key,
    required this.kundliResult,
    required this.kundliInput,
  });

  // North Indian chart: house positions in the diamond grid.
  // The Lagna (ascendant) sign occupies the top-center diamond (position 0).
  // Houses go clockwise: 1=top, 2=top-right, 3=right, 4=bottom-right,
  // 5=bottom, 6=bottom-left, 7=left, 8=top-left ... (12 houses total)
  // Each house corresponds to a zodiac sign number (0=Aries ... 11=Pisces)

  static const _signs = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  // North Indian house grid positions (center x,y as fraction of chart size)
  // Houses are fixed in NI chart layout; sign number shifts based on lagna
  static const _houseOffsets = [
    // house 1 (Lagna) - top center diamond
    Offset(0.5, 0.17),
    // house 2 - top right
    Offset(0.75, 0.28),
    // house 3 - right
    Offset(0.83, 0.5),
    // house 4 - bottom right
    Offset(0.75, 0.72),
    // house 5 - bottom center
    Offset(0.5, 0.83),
    // house 6 - bottom left
    Offset(0.25, 0.72),
    // house 7 - left
    Offset(0.17, 0.5),
    // house 8 - top left
    Offset(0.25, 0.28),
    // house 9 - inner top-right
    Offset(0.65, 0.38),
    // house 10 - inner bottom-right
    Offset(0.65, 0.62),
    // house 11 - inner bottom-left
    Offset(0.35, 0.62),
    // house 12 - inner top-left
    Offset(0.35, 0.38),
  ];

  int _signIndex(String signName) => _signs.indexOf(signName);

  List<List<String>> _buildHousePlanets() {
    final lagnaSignIdx = _signIndex(kundliResult.ascendant);
    // houseContents[houseNum (0-based)] = list of planet abbreviations
    final houseContents = List.generate(12, (_) => <String>[]);
    // Add Ascendant marker to house 1
    houseContents[0].add('As');

    for (final planet in kundliResult.planets) {
      final signIdx = _signIndex(planet.sign);
      if (signIdx == -1) continue;
      // House number = (signIdx - lagnaSignIdx + 12) % 12
      final houseNum = (signIdx - lagnaSignIdx + 12) % 12;
      houseContents[houseNum].add(_planetAbbr(planet.planet));
    }
    return houseContents;
  }

  String _planetAbbr(Planet p) {
    switch (p) {
      case Planet.sun:     return 'Su';
      case Planet.moon:    return 'Mo';
      case Planet.mars:    return 'Ma';
      case Planet.mercury: return 'Me';
      case Planet.jupiter: return 'Ju';
      case Planet.venus:   return 'Ve';
      case Planet.saturn:  return 'Sa';
      case Planet.rahu:    return 'Ra';
      case Planet.ketu:    return 'Ke';
    }
  }

  Color _planetColor(String abbr) {
    const benefics = {'Ju', 'Ve', 'Mo', 'Me'};
    const malefics = {'Su', 'Ma', 'Sa', 'Ra', 'Ke'};
    if (abbr == 'As') return Colors.amber.shade300;
    if (benefics.contains(abbr)) return Colors.lightBlue.shade300;
    if (malefics.contains(abbr)) return Colors.redAccent.shade100;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final housePlanets = _buildHousePlanets();
    final lagnaSignIdx = _signIndex(kundliResult.ascendant);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1030),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('North Indian Kundli',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(kundliInput.name,
                style: TextStyle(fontSize: 12, color: Colors.purple.shade200)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart
            Center(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1030),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: NorthIndianChartPainter(
                    housePlanets: housePlanets,
                    lagnaSignIdx: lagnaSignIdx,
                    signs: _signs,
                    planetColor: _planetColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Legend
            _buildLegend(),
            const SizedBox(height: 24),

            // House details
            _buildHouseTable(housePlanets, lagnaSignIdx),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Planet Abbreviations',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendItem('Su', 'Sun', Colors.redAccent.shade100),
              _legendItem('Mo', 'Moon', Colors.lightBlue.shade300),
              _legendItem('Ma', 'Mars', Colors.redAccent.shade100),
              _legendItem('Me', 'Mercury', Colors.lightBlue.shade300),
              _legendItem('Ju', 'Jupiter', Colors.lightBlue.shade300),
              _legendItem('Ve', 'Venus', Colors.lightBlue.shade300),
              _legendItem('Sa', 'Saturn', Colors.redAccent.shade100),
              _legendItem('Ra', 'Rahu', Colors.redAccent.shade100),
              _legendItem('Ke', 'Ketu', Colors.redAccent.shade100),
              _legendItem('As', 'Ascendant', Colors.amber.shade300),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: Colors.lightBlue.shade300, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Benefic planet', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: Colors.redAccent.shade100, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Malefic planet', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String abbr, String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(abbr, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 4),
        Text(name, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildHouseTable(List<List<String>> housePlanets, int lagnaSignIdx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('House Details',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            children: [
              TableRow(children: [
                _th('House'), _th('Sign'), _th('Planets'),
              ]),
              ...List.generate(12, (i) {
                final signIdx = (lagnaSignIdx + i) % 12;
                final sign = _signs[signIdx];
                final planets = housePlanets[i];
                return TableRow(children: [
                  _td('${i + 1}', bold: true, color: Colors.purple.shade200),
                  _td(sign),
                  planets.isEmpty
                      ? _td('—', color: Colors.white30)
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 6,
                            children: planets.map((p) => Text(
                              p,
                              style: TextStyle(
                                color: _planetColor(p),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )).toList(),
                          ),
                        ),
                ]);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: TextStyle(
                color: Colors.purple.shade300,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      );

  Widget _td(String text, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: TextStyle(
                color: color ?? Colors.white70,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      );
}

// ---------------------------------------------------------------------------
// Custom Painter — North Indian Diamond Chart
// ---------------------------------------------------------------------------
class NorthIndianChartPainter extends CustomPainter {
  final List<List<String>> housePlanets;
  final int lagnaSignIdx;
  final List<String> signs;
  final Color Function(String) planetColor;

  NorthIndianChartPainter({
    required this.housePlanets,
    required this.lagnaSignIdx,
    required this.signs,
    required this.planetColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Outer square
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

    // Inner diamond
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(path, paint);

    // Diagonals dividing corners into 2 triangles each
    canvas.drawLine(Offset(0, 0), Offset(w / 2, h / 2), paint);
    canvas.drawLine(Offset(w, 0), Offset(w / 2, h / 2), paint);
    canvas.drawLine(Offset(w, h), Offset(w / 2, h / 2), paint);
    canvas.drawLine(Offset(0, h), Offset(w / 2, h / 2), paint);

    // House centers for NI chart (12 positions)
    final centers = [
      Offset(w * 0.5,  h * 0.18),  // H1  top diamond
      Offset(w * 0.77, h * 0.26),  // H2  top-right corner upper
      Offset(w * 0.82, h * 0.5),   // H3  right diamond
      Offset(w * 0.77, h * 0.74),  // H4  bottom-right corner lower
      Offset(w * 0.5,  h * 0.82),  // H5  bottom diamond
      Offset(w * 0.23, h * 0.74),  // H6  bottom-left corner lower
      Offset(w * 0.18, h * 0.5),   // H7  left diamond
      Offset(w * 0.23, h * 0.26),  // H8  top-left corner upper
      Offset(w * 0.64, h * 0.38),  // H9  inner top-right
      Offset(w * 0.64, h * 0.62),  // H10 inner bottom-right
      Offset(w * 0.36, h * 0.62),  // H11 inner bottom-left
      Offset(w * 0.36, h * 0.38),  // H12 inner top-left
    ];

    for (int i = 0; i < 12; i++) {
      final center = centers[i];
      final signIdx = (lagnaSignIdx + i) % 12;
      final signAbbr = _signAbbr(signs[signIdx]);
      final planets = housePlanets[i];

      // House number (small, top-left of center)
      _drawText(canvas, '${i + 1}', center + Offset(-18, -22),
          color: Colors.white24, fontSize: 9);

      // Sign abbreviation
      _drawText(canvas, signAbbr, center + Offset(0, -8),
          color: Colors.purple.shade200, fontSize: 10);

      // Planet abbreviations stacked below sign
      for (int j = 0; j < planets.length; j++) {
        final p = planets[j];
        _drawText(canvas, p, center + Offset(0, 6 + j * 13),
            color: planetColor(p), fontSize: 11, bold: true);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset position,
      {Color color = Colors.white, double fontSize = 11, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  String _signAbbr(String sign) {
    const abbrs = {
      'Aries': 'Ari', 'Taurus': 'Tau', 'Gemini': 'Gem',
      'Cancer': 'Can', 'Leo': 'Leo', 'Virgo': 'Vir',
      'Libra': 'Lib', 'Scorpio': 'Sco', 'Sagittarius': 'Sag',
      'Capricorn': 'Cap', 'Aquarius': 'Aqu', 'Pisces': 'Pis',
    };
    return abbrs[sign] ?? sign.substring(0, 3);
  }

  @override
  bool shouldRepaint(covariant NorthIndianChartPainter old) =>
      old.lagnaSignIdx != lagnaSignIdx;
}