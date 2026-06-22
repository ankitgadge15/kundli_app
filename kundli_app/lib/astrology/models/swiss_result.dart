import 'planetary_position.dart';

class SwissResult {
  final double ayanamsa;
  final List<PlanetaryPosition> planets;

  const SwissResult({
    required this.ayanamsa,
    required this.planets,
  });
}