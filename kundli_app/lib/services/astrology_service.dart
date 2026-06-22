import '../models/kundli_input_model.dart';
import '../models/kundli_result_model.dart';
import '../astrology/engine/kundli_engine.dart';

class AstrologyService {
  final KundliEngine _engine = KundliEngine();

  Future<KundliResult> generateKundli(
    KundliInput input,
  ) async {
    return _engine.generate(input);
  }
}