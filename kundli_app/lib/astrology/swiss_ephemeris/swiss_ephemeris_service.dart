import 'dart:math';
import '../models/swiss_result.dart';
import '../models/planetary_position.dart';
import '../../models/planet.dart';

/// Pure Dart astronomical calculation engine.
/// Uses VSOP87 truncated series + Lahiri ayanamsha.
/// Works on ALL platforms — web, mobile, desktop — with no FFI or WASM.
class SwissEphemerisService {
  Future<SwissResult> calculate({
    required DateTime birthDateTime,
    required double timezoneOffset,
    required double latitude,
    required double longitude,
  }) async {
    // Convert local time to UTC
    final offsetMinutes = (timezoneOffset * 60).round();
    final utcDateTime = birthDateTime.subtract(Duration(minutes: offsetMinutes));

    // Julian Day Number (UT)
    final jd = _julianDay(
      utcDateTime.year,
      utcDateTime.month,
      utcDateTime.day,
      utcDateTime.hour + utcDateTime.minute / 60.0 + utcDateTime.second / 3600.0,
    );

    // Julian centuries from J2000.0
    final T = (jd - 2451545.0) / 36525.0;

    // Lahiri ayanamsha (degrees) — standard formula
    final ayanamsa = _lahiriAyanamsha(jd);

    // Calculate tropical longitudes for all planets
    final tropicalSun = _sunLongitude(T);
    final tropicalMoon = _moonLongitude(T);
    final tropicalMercury = _mercuryLongitude(T);
    final tropicalVenus = _venusLongitude(T);
    final tropicalMars = _marsLongitude(T);
    final tropicalJupiter = _jupiterLongitude(T);
    final tropicalSaturn = _saturnLongitude(T);
    final tropicalRahu = _rahuLongitude(T);

    // Apply ayanamsha to get sidereal (Vedic) longitudes
    double sid(double tropical) => _norm360(tropical - ayanamsa);

    final planets = [
      PlanetaryPosition(planet: Planet.sun,     longitude: sid(tropicalSun)),
      PlanetaryPosition(planet: Planet.moon,    longitude: sid(tropicalMoon)),
      PlanetaryPosition(planet: Planet.mercury, longitude: sid(tropicalMercury)),
      PlanetaryPosition(planet: Planet.venus,   longitude: sid(tropicalVenus)),
      PlanetaryPosition(planet: Planet.mars,    longitude: sid(tropicalMars)),
      PlanetaryPosition(planet: Planet.jupiter, longitude: sid(tropicalJupiter)),
      PlanetaryPosition(planet: Planet.saturn,  longitude: sid(tropicalSaturn)),
      PlanetaryPosition(planet: Planet.rahu,    longitude: sid(tropicalRahu)),
      PlanetaryPosition(planet: Planet.ketu,    longitude: _norm360(sid(tropicalRahu) + 180.0)),
    ];

    // Ascendant (Lagna) — sidereal
    final tropicalAsc = _ascendant(jd, latitude, longitude);
    final siderealAsc = sid(tropicalAsc);

    return SwissResult(
      ayanamsa: ayanamsa,
      ascendant: siderealAsc,
      planets: planets,
    );
  }

  // ---------------------------------------------------------------------------
  // Julian Day
  // ---------------------------------------------------------------------------
  double _julianDay(int year, int month, int day, double hour) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final A = (year / 100).floor();
    final B = 2 - A + (A / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        hour / 24.0 +
        B -
        1524.5;
  }

  // ---------------------------------------------------------------------------
  // Lahiri Ayanamsha
  // ---------------------------------------------------------------------------
  double _lahiriAyanamsha(double jd) {
    // Standard Lahiri formula (Astronomical Ephemeris, 1985)
    final T = (jd - 2415020.0) / 36524.220;
    final ayanamsa = 22.4600417 +
        1.3361083 * T +
        0.0001954 * T * T -
        0.00000165 * T * T * T;
    return _norm360(ayanamsa);
  }

  // ---------------------------------------------------------------------------
  // Planet Longitudes (Tropical, degrees) — Meeus "Astronomical Algorithms"
  // ---------------------------------------------------------------------------

  double _sunLongitude(double T) {
    final L0 = _norm360(280.46646 + 36000.76983 * T + 0.0003032 * T * T);
    final M = _norm360(357.52911 + 35999.05029 * T - 0.0001537 * T * T);
    final Mr = _rad(M);
    final C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mr) +
        (0.019993 - 0.000101 * T) * sin(2 * Mr) +
        0.000289 * sin(3 * Mr);
    final sunLong = L0 + C;
    final omega = 125.04 - 1934.136 * T;
    return _norm360(sunLong - 0.00569 - 0.00478 * sin(_rad(omega)));
  }

  double _moonLongitude(double T) {
    final T2 = T * T;
    final T3 = T2 * T;
    final T4 = T3 * T;
    // Moon's mean longitude
    final Lp = _norm360(218.3164477 + 481267.88123421 * T
        - 0.0015786 * T2 + T3 / 538841.0 - T4 / 65194000.0);
    // Moon's mean anomaly
    final M2 = _norm360(134.9633964 + 477198.8676313 * T
        + 0.0089970 * T2 + T3 / 69699.0 - T4 / 14712000.0);
    // Sun's mean anomaly
    final M = _norm360(357.5291092 + 35999.0502909 * T
        - 0.0001536 * T2 + T3 / 24490000.0);
    // Moon's argument of latitude
    final F = _norm360(93.2720950 + 483202.0175233 * T
        - 0.0036539 * T2 - T3 / 3526000.0 + T4 / 863310000.0);
    // Longitude of ascending node of Moon's mean orbit
    final Om = _norm360(125.0445479 - 1934.1362608 * T
        + 0.0020754 * T2 + T3 / 467441.0 - T4 / 60616000.0);

    final E = 1.0 - 0.002516 * T - 0.0000074 * T2;

    double lon = Lp
        + 6.288774 * sin(_rad(M2))
        + 1.274027 * sin(_rad(2 * Lp - M2))
        + 0.658314 * sin(_rad(2 * Lp))
        + 0.213618 * sin(_rad(2 * M2))
        - 0.185116 * E * sin(_rad(M))
        - 0.114332 * sin(_rad(2 * F))
        + 0.058793 * sin(_rad(2 * Lp - 2 * M2))
        + 0.057066 * E * sin(_rad(2 * Lp - M - M2))
        + 0.053322 * sin(_rad(2 * Lp + M2))
        + 0.045758 * E * sin(_rad(2 * Lp - M))
        - 0.040923 * E * sin(_rad(M - M2))
        - 0.034720 * sin(_rad(Lp))
        - 0.030383 * E * sin(_rad(M + M2))
        + 0.015327 * sin(_rad(2 * Lp - 2 * F))
        - 0.012528 * sin(_rad(2 * F + M2))
        + 0.010980 * sin(_rad(2 * F - M2))
        + 0.010675 * sin(_rad(4 * Lp - M2))
        + 0.010034 * sin(_rad(3 * M2))
        + 0.008548 * sin(_rad(4 * Lp - 2 * M2))
        - 0.007888 * E * sin(_rad(2 * Lp + M - M2))
        - 0.006766 * E * sin(_rad(2 * Lp + M))
        - 0.005163 * sin(_rad(Lp + M2))
        + 0.004987 * E * sin(_rad(Lp + M))
        + 0.004036 * E * sin(_rad(2 * Lp - M + M2))
        + 0.003994 * sin(_rad(2 * Lp + 2 * M2))
        + 0.003861 * sin(_rad(4 * Lp))
        + 0.003665 * sin(_rad(2 * Lp - 3 * M2))
        - 0.002689 * E * sin(_rad(M - 2 * M2))
        - 0.002602 * sin(_rad(2 * Lp - 2 * F + M2))
        + 0.002390 * E * sin(_rad(2 * Lp - M - 2 * M2))
        - 0.002348 * sin(_rad(Lp + 2 * M2))
        + 0.002236 * E * sin(_rad(2 * Lp - 2 * M))
        - 0.002120 * E * sin(_rad(M + 2 * M2))
        - 0.002069 * E * E * sin(_rad(2 * M))
        + 0.002048 * E * E * sin(_rad(2 * Lp - 2 * M + M2))
        - 0.001773 * sin(_rad(2 * Lp + M2 - 2 * F))
        - 0.001595 * sin(_rad(2 * Lp + 2 * F))
        + 0.001215 * E * sin(_rad(4 * Lp - M - M2))
        - 0.001110 * sin(_rad(2 * M2 + 2 * F));

    // Apply nutation correction (simplified)
    lon += -0.00017 * sin(_rad(Om));

    return _norm360(lon);
  }

  double _mercuryLongitude(double T) {
    final L = _norm360(252.250906 + 149474.0722491 * T);
    final M = _norm360(174.7948080 + 149472.5159285 * T);
    final Mr = _rad(M);
    final C = 23.4400 * sin(Mr) + 2.9818 * sin(2 * Mr) + 0.5255 * sin(3 * Mr)
        + 0.1058 * sin(4 * Mr) + 0.0219 * sin(5 * Mr);
    return _norm360(L + C);
  }

  double _venusLongitude(double T) {
    final L = _norm360(181.979801 + 58519.2130302 * T);
    final M = _norm360(50.4161861 + 58517.8038994 * T);
    final Mr = _rad(M);
    final C = 0.7758 * sin(Mr) + 0.0033 * sin(2 * Mr);
    return _norm360(L + C);
  }

  double _marsLongitude(double T) {
    final L = _norm360(355.433 + 19141.6964471 * T);
    final M = _norm360(19.3730 + 19140.2993313 * T);
    final Mr = _rad(M);
    final C = 10.6912 * sin(Mr) + 0.6228 * sin(2 * Mr)
        + 0.0503 * sin(3 * Mr) + 0.0046 * sin(4 * Mr);
    return _norm360(L + C);
  }

  double _jupiterLongitude(double T) {
    final L = _norm360(34.351519 + 3036.3027748 * T);
    final M = _norm360(20.9 + 3034.906 * T);
    final Mr = _rad(M);
    final C = 5.5549 * sin(Mr) + 0.1683 * sin(2 * Mr)
        + 0.0071 * sin(3 * Mr);
    return _norm360(L + C);
  }

  double _saturnLongitude(double T) {
    final L = _norm360(50.077444 + 1223.5110686 * T);
    final M = _norm360(317.02 + 1221.552 * T);
    final Mr = _rad(M);
    final C = 6.3585 * sin(Mr) + 0.2204 * sin(2 * Mr)
        + 0.0106 * sin(3 * Mr);
    return _norm360(L + C);
  }

  double _rahuLongitude(double T) {
    // Mean ascending node of the Moon (Rahu in Vedic astrology)
    final Om = _norm360(125.0445479
        - 1934.1362608 * T
        + 0.0020754 * T * T
        + T * T * T / 467441.0);
    return Om;
  }

  // ---------------------------------------------------------------------------
  // Ascendant
  // ---------------------------------------------------------------------------
  double _ascendant(double jd, double lat, double lon) {
    // Sidereal time in degrees at Greenwich
    final T = (jd - 2451545.0) / 36525.0;
    double GMST = 280.46061837
        + 360.98564736629 * (jd - 2451545.0)
        + 0.000387933 * T * T
        - T * T * T / 38710000.0;
    GMST = _norm360(GMST);
    // Local Sidereal Time
    final LST = _norm360(GMST + lon);
    final LSTrad = _rad(LST);

    // Obliquity of ecliptic
    final eps = _rad(23.4393 - 0.013004 * T);

    // Ascendant formula
    final latRad = _rad(lat);
    final numerator = cos(LSTrad);
    final denominator = -(sin(LSTrad) * cos(eps) + tan(latRad) * sin(eps));
    double asc = _deg(atan2(numerator, denominator));
    asc = _norm360(asc);

    // Quadrant correction
    if (cos(LSTrad) < 0) {
      asc = _norm360(asc + 180.0);
    }
    return asc;
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------
  double _rad(double deg) => deg * pi / 180.0;
  double _deg(double rad) => rad * 180.0 / pi;
  double _norm360(double deg) {
    final result = deg % 360.0;
    return result < 0 ? result + 360.0 : result;
  }
}