import '../models/kundli_input_model.dart';
import '../models/kundli_result_model.dart';

class AstrologyService {
  Future<KundliResult> generateKundli(
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