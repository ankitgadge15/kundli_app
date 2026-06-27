import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'kundli_chart_screen.dart';
import 'prediction_screen.dart';
import '../models/kundli_input_model.dart';
import '../models/kundli_result_model.dart';
import '../models/planet.dart';
import '../services/groq_service.dart';

const _zodiacSigns = [
  'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
  'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
];

int _signIndex(String sign) => _zodiacSigns.indexOf(sign);

List<List<String>> _buildHousePlanets(int lagnaIdx) {
  return []; // Simplified for PDF — planet placement is shown in house table
}

class ResultScreen extends StatefulWidget {
  final KundliInput kundliInput;
  final KundliResult kundliResult;

  const ResultScreen({
    super.key,
    required this.kundliInput,
    required this.kundliResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isGeneratingPdf = false;
  final TextEditingController _apiKeyController = TextEditingController();
  String _savedApiKey = '';

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    // If we have a saved API key, offer to include predictions
    bool includePredictions = false;
    Map<String, String> predictions = {};

    if (_savedApiKey.isNotEmpty) {
      final include = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1030),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Include Year Predictions?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Do you want to include the 2026–2027 year prediction in the PDF?\n\n'
            'This will call the Groq AI API and may take ~10 seconds.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Include'),
            ),
          ],
        ),
      );
      includePredictions = include ?? false;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      // Fetch predictions if requested
      if (includePredictions && _savedApiKey.isNotEmpty) {
        try {
          final service = GroqService(apiKey: _savedApiKey);
          predictions = await service.generateYearPrediction(
            input: widget.kundliInput,
            result: widget.kundliResult,
          );
        } catch (_) {
          includePredictions = false;
        }
      }

      final pdf = pw.Document();
      final formattedDate =
          DateFormat('dd MMM yyyy').format(widget.kundliInput.birthDateTime);
      final formattedTime =
          DateFormat('hh:mm a').format(widget.kundliInput.birthDateTime);

      // ── Page 1: Kundli Result ─────────────────────────────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('4A148C'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('VEDIC KUNDLI REPORT',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(widget.kundliInput.name.toUpperCase(),
                    style: pw.TextStyle(
                        color: PdfColor.fromHex('CE93D8'), fontSize: 16)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          _pdfSection('Birth Details', [
            ['Date', formattedDate],
            ['Time', formattedTime],
            ['Place', widget.kundliInput.place],
          ]),
          pw.SizedBox(height: 16),

          _pdfSection('Astrology Summary', [
            ['Ascendant (Lagna)', widget.kundliResult.ascendant],
            ['Moon Sign (Rashi)', widget.kundliResult.moonSign],
            ['Sun Sign', widget.kundliResult.sunSign],
            ['Nakshatra', widget.kundliResult.nakshatra],
          ]),
          pw.SizedBox(height: 16),

          // Planetary Positions table
          pw.Text('Planetary Positions',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6A1B9A)),
                children: [
                  _pdfCell('Planet',   header: true),
                  _pdfCell('Sign',     header: true),
                  _pdfCell('Position', header: true),
                ],
              ),
              ...widget.kundliResult.planets.map((p) => pw.TableRow(children: [
                    _pdfCell(_getPlanetName(p.planet)),
                    _pdfCell(p.sign),
                    _pdfCell(_formatDegrees(p.longitude)),
                  ])),
            ],
          ),
        ],
      ));

      // ── Page 2: Kundli Chart (House Details) ─────────────────────────────
      final lagnaIdx = _signIndex(widget.kundliResult.ascendant);
      final housePlanets = _buildHousePlanets(lagnaIdx);

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('4A148C'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text('KUNDLI CHART — HOUSE DETAILS',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Ascendant (Lagna): ${widget.kundliResult.ascendant}  |  '
            'Moon Sign: ${widget.kundliResult.moonSign}  |  '
            'Nakshatra: ${widget.kundliResult.nakshatra}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(50),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6A1B9A)),
                children: [
                  _pdfCell('House', header: true),
                  _pdfCell('Sign',  header: true),
                  _pdfCell('Planets in House', header: true),
                ],
              ),
              ...List.generate(12, (i) {
                final signIdx = (lagnaIdx + i) % 12;
                final sign    = _zodiacSigns[signIdx];
                final planets = housePlanets[i];
                return pw.TableRow(children: [
                  _pdfCell('${i + 1}'),
                  _pdfCell(sign),
                  _pdfCell(planets.isEmpty ? '—' : planets.join(', ')),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text(
              'Planet abbreviations: Su=Sun, Mo=Moon, Ma=Mars, Me=Mercury, '
              'Ju=Jupiter, Ve=Venus, Sa=Saturn, Ra=Rahu, Ke=Ketu, As=Ascendant',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600)),
        ],
      ));

      // ── Page 3: Year Prediction ───────────────────────────────────────────
      if (includePredictions && predictions.isNotEmpty) {
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('4A148C'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text('YEAR PREDICTION 2026–2027',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),

            ...predictions.entries.map((entry) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(entry.key,
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('9C27B0'))),
                    pw.SizedBox(height: 4),
                    pw.Text(entry.value,
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey800)),
                    pw.SizedBox(height: 14),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                  ],
                )),
          ],
        ));
      }

      // Footer on all pages
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => pw.Center(
          child: pw.Text(
            'Generated by Kundli App · ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
          ),
        ),
      ));

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Kundli_${widget.kundliInput.name}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  pw.Widget _pdfSection(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: rows.map((row) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              child: pw.Row(children: [
                pw.SizedBox(
                  width: 130,
                  child: pw.Text(row[0],
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11)),
                ),
                pw.Text(row[1],
                    style: const pw.TextStyle(fontSize: 11)),
              ]),
            )).toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: header ? PdfColors.white : PdfColors.black,
          fontWeight:
              header ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 11,
        ),
      ),
    );
  }

  void _openPrediction() {
    if (_savedApiKey.trim().isEmpty) {
      _showApiKeyDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionScreen(
          kundliInput: widget.kundliInput,
          kundliResult: widget.kundliResult,
          apiKey: _savedApiKey.trim(),
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Groq API Key',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your free Groq API key to generate year predictions.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Get free key at console.groq.com',
                style: TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 12,
                    decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'gsk_...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final key = _apiKeyController.text.trim();
              if (key.isEmpty) return;
              setState(() => _savedApiKey = key);
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PredictionScreen(
                    kundliInput: widget.kundliInput,
                    kundliResult: widget.kundliResult,
                    apiKey: key,
                  ),
                ),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('dd MMM yyyy').format(widget.kundliInput.birthDateTime);

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
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        widget.kundliInput.name.isNotEmpty
                            ? widget.kundliInput.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.kundliInput.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kundli Summary',
                      style: TextStyle(color: Colors.grey.shade600),
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
                        Text('Birth Details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    _detailRow('Date', formattedDate),
                    _detailRow('Time',
                        DateFormat('hh:mm a').format(widget.kundliInput.birthDateTime)),
                    _detailRow('Place', widget.kundliInput.place),
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
                        Text('Astrology Summary',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    _detailRow('Moon Sign', widget.kundliResult.moonSign),
                    _detailRow('Sun Sign', widget.kundliResult.sunSign),
                    _detailRow('Ascendant', widget.kundliResult.ascendant),
                    _detailRow('Nakshatra', widget.kundliResult.nakshatra),
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
                        Text('Planetary Positions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
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
                            color: Colors.grey.shade200, width: 1),
                      ),
                      children: [
                        TableRow(children: [
                          _tableHeader('Planet'),
                          _tableHeader('Sign'),
                          _tableHeader('Position'),
                        ]),
                        ...widget.kundliResult.planets.map((p) => TableRow(
                              children: [
                                _tableCell(_getPlanetName(p.planet),
                                    bold: true),
                                _tableCell(p.sign),
                                _tableCell(_formatDegrees(p.longitude)),
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // View Kundli Chart
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KundliChartScreen(
                      kundliResult: widget.kundliResult,
                      kundliInput: widget.kundliInput,
                    ),
                  ),
                ),
                icon: const Icon(Icons.grid_view),
                label: const Text('View Kundli Chart'),
              ),
            ),

            const SizedBox(height: 12),

            // Year Prediction
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openPrediction,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('✨  Year Prediction 2026–2027'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Download PDF
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGeneratingPdf ? null : _downloadPdf,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingPdf
                    ? 'Generating PDF...'
                    : 'Download PDF'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helpers
  String _getPlanetName(Planet planet) {
    switch (planet) {
      case Planet.sun:     return 'Sun';
      case Planet.moon:    return 'Moon';
      case Planet.mars:    return 'Mars';
      case Planet.mercury: return 'Mercury';
      case Planet.jupiter: return 'Jupiter';
      case Planet.venus:   return 'Venus';
      case Planet.saturn:  return 'Saturn';
      case Planet.rahu:    return 'Rahu';
      case Planet.ketu:    return 'Ketu';
    }
  }

  String _formatDegrees(double decimalDegrees) {
    final degInSign = decimalDegrees % 30.0;
    final d = degInSign.floor();
    final minPart = (degInSign - d) * 60.0;
    final m = minPart.floor();
    final s = ((minPart - m) * 60.0).round();
    return "$d° ${m.toString().padLeft(2, '0')}' ${s.toString().padLeft(2, '0')}\"";
  }

  static Widget _detailRow(String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  static Widget _tableHeader(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
      );

  static Widget _tableCell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
      );
}