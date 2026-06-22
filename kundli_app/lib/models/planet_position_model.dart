import 'planet.dart';

class PlanetPosition {
  final Planet planet;
  final String sign;
  final double longitude;

  const PlanetPosition({
    required this.planet,
    required this.sign,
    required this.longitude,
  });
}