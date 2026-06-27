import 'package:flutter/material.dart';
import '../models/kundli_input_model.dart';
import '../models/kundli_result_model.dart';
import '../services/groq_service.dart';

class PredictionScreen extends StatefulWidget {
  final KundliInput kundliInput;
  final KundliResult kundliResult;
  final String apiKey;

  const PredictionScreen({
    super.key,
    required this.kundliInput,
    required this.kundliResult,
    required this.apiKey,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  Map<String, String>? _predictions;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    try {
      final service = GroqService(apiKey: widget.apiKey);
      final predictions = await service.generateYearPrediction(
        input: widget.kundliInput,
        result: widget.kundliResult,
      );
      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1030),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Year Prediction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '2026 – 2027 · ${widget.kundliInput.name}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple.shade200,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading && _error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadPredictions();
              },
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView(theme)
              : _buildPredictionsView(theme),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.purpleAccent,
            ),
          ),
          SizedBox(height: 24),
          Text(
            '✨ Consulting the stars...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Generating 24 months of predictions',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Prediction failed',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadPredictions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsView(ThemeData theme) {
    final predictions = _predictions!;
    final keys = predictions.keys.toList();

    // Split into 2026 and 2027
    final months2026 = keys.where((k) => k.contains('2026')).toList();
    final months2027 = keys.where((k) => k.contains('2027')).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary banner
        _buildBanner(),
        const SizedBox(height: 24),

        if (months2026.isNotEmpty) ...[
          _buildYearHeader('2026'),
          const SizedBox(height: 12),
          ...months2026.map((month) => _buildMonthCard(
                month,
                predictions[month] ?? '',
                isCurrentYear: true,
              )),
          const SizedBox(height: 24),
        ],

        if (months2027.isNotEmpty) ...[
          _buildYearHeader('2027'),
          const SizedBox(height: 12),
          ...months2027.map((month) => _buildMonthCard(
                month,
                predictions[month] ?? '',
                isCurrentYear: false,
              )),
        ],
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B21A8), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔮', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vedic Year Forecast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your Lagna (${widget.kundliResult.ascendant}), '
                  'Moon in ${widget.kundliResult.moonSign}, '
                  'Nakshatra ${widget.kundliResult.nakshatra}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearHeader(String year) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: year == '2026'
                ? Colors.purple.shade800
                : Colors.indigo.shade800,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '⭐ $year',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.15), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildMonthCard(String month, String prediction, {required bool isCurrentYear}) {
    final monthName = month.split(' ')[0];
    final emoji = _monthEmoji(monthName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentYear
              ? Colors.purple.withOpacity(0.3)
              : Colors.indigo.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCurrentYear
                  ? Colors.purple.withOpacity(0.2)
                  : Colors.indigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          title: Text(
            monthName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            _previewText(prediction),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
          iconColor: Colors.purple.shade300,
          collapsedIconColor: Colors.white38,
          children: [
            Text(
              prediction,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewText(String text) {
    if (text.length <= 60) return text;
    return '${text.substring(0, 60)}...';
  }

  String _monthEmoji(String month) {
    const map = {
      'JANUARY': '❄️', 'FEBRUARY': '💝', 'MARCH': '🌸',
      'APRIL': '🌿', 'MAY': '🌺', 'JUNE': '☀️',
      'JULY': '🌊', 'AUGUST': '🍃', 'SEPTEMBER': '🍂',
      'OCTOBER': '🎃', 'NOVEMBER': '🍁', 'DECEMBER': '⭐',
    };
    return map[month.toUpperCase()] ?? '🔮';
  }
}
