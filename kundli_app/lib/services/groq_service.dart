import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/kundli_result_model.dart';
import '../models/kundli_input_model.dart';
import '../models/planet.dart';

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  final String apiKey;

  GroqService({required this.apiKey});

  /// Generates month-wise year predictions for 2026-2027
  Future<Map<String, String>> generateYearPrediction({
    required KundliInput input,
    required KundliResult result,
  }) async {
    final prompt = _buildPrompt(input, result);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert Vedic astrologer with deep knowledge of '
                    'Jyotish (Indian astrology). You provide insightful, '
                    'positive yet realistic month-wise predictions. Each '
                    'month prediction should be 3-4 sentences covering '
                    'career, relationships, health, and finances briefly. '
                    'Be specific and encouraging. Do not use markdown, '
                    'just plain text paragraphs.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 4000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content =
        data['choices'][0]['message']['content'] as String;

    return _parseMonthlyPredictions(content);
  }

  String _buildPrompt(KundliInput input, KundliResult result) {
    final planetLines = result.planets.map((p) {
      final name = _planetName(p.planet);
      return '$name in ${p.sign}';
    }).join(', ');

    return '''
Generate month-wise Vedic astrology predictions for the year 2026 and 2027 (24 months total) for the following person:

Name: ${input.name}
Date of Birth: ${input.birthDateTime.day}/${input.birthDateTime.month}/${input.birthDateTime.year}
Place of Birth: ${input.place}

Vedic Birth Chart:
- Ascendant (Lagna): ${result.ascendant}
- Moon Sign (Rashi): ${result.moonSign}
- Sun Sign: ${result.sunSign}
- Nakshatra (Birth Star): ${result.nakshatra}
- Planetary Positions: $planetLines

Please provide predictions for each of these 24 months in this EXACT format (use these exact month labels):

JANUARY 2026:
[prediction here]

FEBRUARY 2026:
[prediction here]

... and so on through DECEMBER 2027.

Focus on: career/finances, relationships, health, and spiritual growth for each month.
''';
  }

  Map<String, String> _parseMonthlyPredictions(String content) {
    final months = <String, String>{};
    final monthLabels = [
      'JANUARY 2026', 'FEBRUARY 2026', 'MARCH 2026', 'APRIL 2026',
      'MAY 2026', 'JUNE 2026', 'JULY 2026', 'AUGUST 2026',
      'SEPTEMBER 2026', 'OCTOBER 2026', 'NOVEMBER 2026', 'DECEMBER 2026',
      'JANUARY 2027', 'FEBRUARY 2027', 'MARCH 2027', 'APRIL 2027',
      'MAY 2027', 'JUNE 2027', 'JULY 2027', 'AUGUST 2027',
      'SEPTEMBER 2027', 'OCTOBER 2027', 'NOVEMBER 2027', 'DECEMBER 2027',
    ];

    for (int i = 0; i < monthLabels.length; i++) {
      final label = monthLabels[i];
      final nextLabel = i + 1 < monthLabels.length ? monthLabels[i + 1] : null;

      final startIdx = content.indexOf('$label:');
      if (startIdx == -1) continue;

      final contentStart = startIdx + label.length + 1;
      final endIdx = nextLabel != null
          ? content.indexOf('$nextLabel:')
          : content.length;

      if (endIdx == -1 || endIdx <= contentStart) continue;

      final prediction = content.substring(contentStart, endIdx).trim();
      months[label] = prediction;
    }

    // Fallback: if parsing failed, return raw content under one key
    if (months.isEmpty) {
      months['PREDICTION'] = content;
    }

    return months;
  }

  String _planetName(Planet planet) {
    switch (planet) {
      case Planet.sun: return 'Sun';
      case Planet.moon: return 'Moon';
      case Planet.mars: return 'Mars';
      case Planet.mercury: return 'Mercury';
      case Planet.jupiter: return 'Jupiter';
      case Planet.venus: return 'Venus';
      case Planet.saturn: return 'Saturn';
      case Planet.rahu: return 'Rahu';
      case Planet.ketu: return 'Ketu';
    }
  }
}
