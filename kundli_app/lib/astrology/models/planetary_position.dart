import '../../models/planet.dart';

class PlanetaryPosition {
  final Planet planet;
  final double longitude;

  const PlanetaryPosition({
    required this.planet,
    required this.longitude,
  });
}