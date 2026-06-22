import '../../models/kundli_input_model.dart';
import '../../models/kundli_result_model.dart';

class KundliEngine {
  Future<KundliResult> generate(
    KundliInput input,
  ) async {
    return const KundliResult(
      ascendant: 'Aries',
      moonSign: 'Taurus',
      sunSign: 'Gemini',
      nakshatra: 'Rohini',
      planets: [],
    );
  }
}