import '../../models/kundli_input_model.dart';
import '../../models/kundli_result_model.dart';
import '../../models/planet_position_model.dart';
import '../../models/planet.dart';
import '../swiss_ephemeris/swiss_ephemeris_service.dart';

class KundliEngine {
  final SwissEphemerisService _swissService = SwissEphemerisService();

  static const List<String> _zodiacSigns = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  static const List<String> _nakshatras = [
    'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra',
    'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni',
    'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha',
    'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana', 'Dhanishta', 'Shatabhisha',
    'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati'
  ];

  String _getZodiacSign(double longitude) {
    double normalized = longitude % 360.0;
    if (normalized < 0) normalized += 360.0;
    int index = (normalized / 30.0).floor();
    return _zodiacSigns[index];
  }

  String _getNakshatra(double longitude) {
    double normalized = longitude % 360.0;
    if (normalized < 0) normalized += 360.0;
    int index = (normalized / (360.0 / 27.0)).floor();
    return _nakshatras[index];
  }

  Future<KundliResult> generate(
    KundliInput input,
  ) async {
    // 1. Call Swiss Ephemeris Service to get raw calculations
    final swissResult = await _swissService.calculate(
      birthDateTime: input.birthDateTime,
      timezoneOffset: input.timezoneOffset,
      latitude: input.latitude,
      longitude: input.longitude,
    );

    // 2. Map planetary positions to PlanetPosition models
    final List<PlanetPosition> planetPositions = [];

    for (final rawPlanet in swissResult.planets) {
      planetPositions.add(
        PlanetPosition(
          planet: rawPlanet.planet,
          sign: _getZodiacSign(rawPlanet.longitude),
          longitude: rawPlanet.longitude,
        ),
      );
    }

    // 3. Extract Sun and Moon positions for quick access
    final sunPos = swissResult.planets.firstWhere((p) => p.planet == Planet.sun);
    final moonPos = swissResult.planets.firstWhere((p) => p.planet == Planet.moon);

    // 4. Return the fully computed KundliResult
    return KundliResult(
      ascendant: _getZodiacSign(swissResult.ascendant),
      moonSign: _getZodiacSign(moonPos.longitude),
      sunSign: _getZodiacSign(sunPos.longitude),
      nakshatra: _getNakshatra(moonPos.longitude),
      planets: planetPositions,
    );
  }
}