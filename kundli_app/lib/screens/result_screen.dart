import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'kundli_chart_screen.dart';
import '../models/kundli_input_model.dart';
import '../models/kundli_result_model.dart';
import '../models/planet.dart';
// import '../services/astrology_service.dart';

class ResultScreen extends StatelessWidget {
  final KundliInput kundliInput;
  final KundliResult kundliResult;
  const ResultScreen({
    super.key,
    required this.kundliInput,
    required this.kundliResult,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMM yyyy').format(kundliInput.birthDateTime);
    // final kundliResult = AstrologyService().generateKundli();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kundli Result'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      child: Text(
                        kundliInput.name.isNotEmpty
                            ? kundliInput.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      kundliInput.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Kundli Summary",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Birth Details
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month),
                        SizedBox(width: 8),
                        Text(
                          "Birth Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    _detailRow("Date", formattedDate),
                    _detailRow("Time", DateFormat('hh:mm a').format(kundliInput.birthDateTime),),
                    _detailRow("Place", kundliInput.place),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Astrology Summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome),
                        SizedBox(width: 8),
                        Text(
                          "Astrology Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    _detailRow("Moon Sign", kundliResult.moonSign),
                    _detailRow("Sun Sign", kundliResult.sunSign),
                    _detailRow("Ascendant", kundliResult.ascendant),
                    _detailRow("Nakshatra", kundliResult.nakshatra),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Planetary Positions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.brightness_5),
                        SizedBox(width: 8),
                        Text(
                          "Planetary Positions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(3),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      children: [
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Planet",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Sign",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Position",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...kundliResult.planets.map((p) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  _getPlanetName(p.planet),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(p.sign),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  _formatDegrees(p.longitude),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KundliChartScreen(),
      ),
    );
  },
                icon: const Icon(Icons.grid_view),
                label: const Text("View Kundli Chart"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Download PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanetName(Planet planet) {
    switch (planet) {
      case Planet.sun: return "Sun";
      case Planet.moon: return "Moon";
      case Planet.mars: return "Mars";
      case Planet.mercury: return "Mercury";
      case Planet.jupiter: return "Jupiter";
      case Planet.venus: return "Venus";
      case Planet.saturn: return "Saturn";
      case Planet.rahu: return "Rahu";
      case Planet.ketu: return "Ketu";
    }
  }

  String _formatDegrees(double decimalDegrees) {
    double degInSign = decimalDegrees % 30.0;
    int d = degInSign.floor();
    double minPart = (degInSign - d) * 60.0;
    int m = minPart.floor();
    double secPart = (minPart - m) * 60.0;
    int s = secPart.round();
    return "$d° ${m.toString().padLeft(2, '0')}' ${s.toString().padLeft(2, '0')}\"";
  }

  static Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}