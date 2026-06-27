import 'planetary_position.dart';

class SwissResult {
  final double ayanamsa;
  final double ascendant;
  final List<PlanetaryPosition> planets;

  const SwissResult({
    required this.ayanamsa,
    required this.ascendant,
    required this.planets,
  });
}