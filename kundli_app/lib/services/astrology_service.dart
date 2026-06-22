import '../models/kundli_input_model.dart';
import '../models/kundli_result_model.dart';

class AstrologyService {
  Future<KundliResult> generateKundli(
    KundliInput input,
  ) async {
    return const KundliResult(
      ascendant: "Coming Soon",
      moonSign: "Coming Soon",
      sunSign: "Coming Soon",
      nakshatra: "Coming Soon",
      planets: [],
    );
  }
}