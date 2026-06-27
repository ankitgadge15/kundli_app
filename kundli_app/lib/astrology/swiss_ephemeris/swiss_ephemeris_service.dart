import 'package:flutter/foundation.dart';
import 'package:swisseph/swisseph.dart';
import '../models/swiss_result.dart';
import '../models/planetary_position.dart';
import '../../models/planet.dart';

class SwissEphemerisService {
  Future<SwissResult> calculate({
    required DateTime birthDateTime,
    required double timezoneOffset,
    required double latitude,
    required double longitude,
  }) async {
    // 1. Locate and load the Swiss Ephemeris FFI library
    final SwissEph swe;
    if (kIsWeb) {
      swe = await SwissEph.load('assets/packages/swisseph/assets/swisseph');
    } else {
      swe = await SwissEph.load();
    }

    // 2. Convert local birth date-time to UTC
    final offsetMinutes = (timezoneOffset * 60).round();
    final utcDateTime = birthDateTime.subtract(Duration(minutes: offsetMinutes));

    // 3. Convert UTC date and time to Julian Day (UT)
    final decimalHour = utcDateTime.hour +
        (utcDateTime.minute / 60.0) +
        (utcDateTime.second / 3600.0);
    final jdUt = swe.julday(
      utcDateTime.year,
      utcDateTime.month,
      utcDateTime.day,
      decimalHour,
    );

    // 4. Configure Lahiri Ayanamsa for sidereal positions
    swe.setSidMode(seSidmLahiri);

    // 5. Get the Ayanamsa value in degrees
    final ayanamsa = swe.getAyanamsaUt(jdUt);

    // 6. Configure flags: Moshier offline ephemeris, high speed, and sidereal calculations
    final flags = seFlgMosEph | seFlgSpeed | seFlgSidereal;

    // 7. Calculate planetary positions
    final List<PlanetaryPosition> planetsList = [];

    final bodiesToCalculate = {
      Planet.sun: seSun,
      Planet.moon: seMoon,
      Planet.mars: seMars,
      Planet.mercury: seMercury,
      Planet.jupiter: seJupiter,
      Planet.venus: seVenus,
      Planet.saturn: seSaturn,
      Planet.rahu: seMeanNode, // Standard mean node for Rahu
    };

    for (final entry in bodiesToCalculate.entries) {
      final calcResult = swe.calcUt(jdUt, entry.value, flags);
      planetsList.add(
        PlanetaryPosition(
          planet: entry.key,
          longitude: calcResult.longitude,
        ),
      );
    }

    // 8. Ketu is always exactly 180 degrees opposite of Rahu
    final rahuPos = planetsList.firstWhere((p) => p.planet == Planet.rahu);
    final ketuLongitude = (rahuPos.longitude + 180.0) % 360.0;
    planetsList.add(
      PlanetaryPosition(
        planet: Planet.ketu,
        longitude: ketuLongitude,
      ),
    );

    // 9. Calculate houses to get the Ascendant (Lagna) longitude
    final houseData = swe.housesEx(
      jdUt,
      seFlgSidereal | seFlgMosEph,
      latitude,
      longitude,
      'P'.codeUnitAt(0), // Placidus system
    );

    return SwissResult(
      ayanamsa: ayanamsa,
      ascendant: houseData.ascendant,
      planets: planetsList,
    );
  }
}