import 'planet_position_model.dart';

class KundliResult {
  final String ascendant;
  final String moonSign;
  final String sunSign;
  final String nakshatra;

  final List<PlanetPosition> planets;

  const KundliResult({
    required this.ascendant,
    required this.moonSign,
    required this.sunSign,
    required this.nakshatra,
    required this.planets,
  });
}