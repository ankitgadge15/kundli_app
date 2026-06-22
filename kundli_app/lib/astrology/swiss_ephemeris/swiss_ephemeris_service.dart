import '../models/swiss_result.dart';

class SwissEphemerisService {
  Future<SwissResult> calculate() async {
    return const SwissResult(
      ayanamsa: 24.0,
      planets: [],
    );
  }
}