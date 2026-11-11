import 'dart:math' as math;

const double _rad = math.pi / 180;

/// Degrees reduced to [0, 360).
double norm360(double d) {
  final r = d % 360;
  return r < 0 ? r + 360 : r;
}

/// Signed difference `a - b` reduced to (-180, 180].
double angleDiff(double a, double b) {
  final d = norm360(a - b);
  return d > 180 ? d - 360 : d;
}

/// Position of the Moon: ecliptic longitude and latitude (degrees, mean
/// equinox of date) and distance (km).
typedef MoonPosition = ({double lon, double lat, double distance});

/// Sun and Moon positions, sidereal time and the Lahiri ayanamsa, in pure
/// Dart. Julian days are UT unless a name says `jde` (dynamical time).
///
/// Sun: Meeus, *Astronomical Algorithms* 2nd ed., ch. 25 (equation of centre,
/// aberration; about 0.01 degree). Moon: ch. 47, all 59 longitude terms, the
/// 30 largest latitude terms and the main distance terms (about 0.003 degree
/// in longitude). All longitudes refer to the mean equinox of date; nutation
/// is left out on purpose because it cancels in the Moon-Sun elongation and
/// in sidereal longitudes (true tropical longitude minus true ayanamsa equals
/// mean tropical longitude minus mean ayanamsa).
abstract final class Astro {
  static const double j2000 = 2451545.0;

  static double julianDay(DateTime utc) => 2440587.5 + utc.millisecondsSinceEpoch / 86400000.0;

  static DateTime fromJulianDay(double jd) =>
      DateTime.fromMillisecondsSinceEpoch(((jd - 2440587.5) * 86400000).round(), isUtc: true);

  /// TT - UT in seconds (Espenak and Meeus polynomials; linear
  /// extrapolation from the observed 2020 value for 2016 to 2050).
  static double deltaT(double jd) {
    final y = 2000 + (jd - j2000) / 365.25;
    if (y < 1900) return -2.79; // before 1900 is not supported; keep the 1900 value
    if (y < 1920) {
      final t = y - 1900;
      return -2.79 + 1.494119 * t - 0.0598939 * t * t + 0.0061966 * t * t * t - 0.000197 * t * t * t * t;
    }
    if (y < 1941) {
      final t = y - 1920;
      return 21.20 + 0.84493 * t - 0.076100 * t * t + 0.0020936 * t * t * t;
    }
    if (y < 1961) {
      final t = y - 1950;
      return 29.07 + 0.407 * t - t * t / 233 + t * t * t / 2547;
    }
    if (y < 1986) {
      final t = y - 1975;
      return 45.45 + 1.067 * t - t * t / 260 - t * t * t / 718;
    }
    if (y < 2005) {
      final t = y - 2000;
      return 63.86 + 0.3345 * t - 0.060374 * t * t + 0.0017275 * t * t * t + 0.000651814 * t * t * t * t +
          0.00002373599 * t * t * t * t * t;
    }
    if (y < 2016) {
      final t = y - 2000;
      return 62.92 + 0.32217 * t + 0.005589 * t * t;
    }
    if (y < 2050) return 69.4 + 0.3 * (y - 2020);
    final u = (y - 1820) / 100;
    return -20 + 32 * u * u - 0.5628 * (2150 - y.clamp(2050, 2150));
  }

  static double _centuries(double jde) => (jde - j2000) / 36525.0;

  static double jde(double jdUt) => jdUt + deltaT(jdUt) / 86400.0;

  /// Mean obliquity of the ecliptic, degrees.
  static double obliquity(double jde) {
    final t = _centuries(jde);
    return 23.439291 - 0.0130042 * t - 1.64e-7 * t * t;
  }

  /// Apparent geocentric longitude of the Sun (degrees) and its distance (AU).
  static ({double lon, double distance}) sun(double jde) {
    final t = _centuries(jde);
    final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    final m = norm360(357.52911 + 35999.05029 * t - 0.0001537 * t * t) * _rad;
    final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(m) +
        (0.019993 - 0.000101 * t) * math.sin(2 * m) +
        0.000289 * math.sin(3 * m);
    final nu = m + c * _rad;
    final r = 1.000001018 * (1 - e * e) / (1 + e * math.cos(nu));
    return (lon: norm360(l0 + c - 0.00569), distance: r);
  }

  // Meeus table 47.A: D, M, M', F, longitude (1e-6 deg), distance (1e-3 km).
  static const _lr = <List<int>>[
    [0, 0, 1, 0, 6288774, -20905355],
    [2, 0, -1, 0, 1274027, -3699111],
    [2, 0, 0, 0, 658314, -2955968],
    [0, 0, 2, 0, 213618, -569925],
    [0, 1, 0, 0, -185116, 48888],
    [0, 0, 0, 2, -114332, -3149],
    [2, 0, -2, 0, 58793, 246158],
    [2, -1, -1, 0, 57066, -152138],
    [2, 0, 1, 0, 53322, -170733],
    [2, -1, 0, 0, 45758, -204586],
    [0, 1, -1, 0, -40923, -129620],
    [1, 0, 0, 0, -34720, 108743],
    [0, 1, 1, 0, -30383, 104755],
    [2, 0, 0, -2, 15327, 10321],
    [0, 0, 1, 2, -12528, 0],
    [0, 0, 1, -2, 10980, 79661],
    [4, 0, -1, 0, 10675, -34782],
    [0, 0, 3, 0, 10034, -23210],
    [4, 0, -2, 0, 8548, -21636],
    [2, 1, -1, 0, -7888, 24208],
    [2, 1, 0, 0, -6766, 30824],
    [1, 0, -1, 0, -5163, -8379],
    [1, 1, 0, 0, 4987, -16675],
    [2, -1, 1, 0, 4036, -12831],
    [2, 0, 2, 0, 3994, -10445],
    [4, 0, 0, 0, 3861, -11650],
    [2, 0, -3, 0, 3665, 14403],
    [0, 1, -2, 0, -2689, -7003],
    [2, 0, -1, 2, -2602, 0],
    [2, -1, -2, 0, 2390, 10056],
    [1, 0, 1, 0, -2348, 6322],
    [2, -2, 0, 0, 2236, -9884],
    [0, 1, 2, 0, -2120, 5751],
    [0, 2, 0, 0, -2069, 0],
    [2, -2, -1, 0, 2048, -4950],
    [2, 0, 1, -2, -1773, 4130],
    [2, 0, 0, 2, -1595, 0],
    [4, -1, -1, 0, 1215, -3958],
    [0, 0, 2, 2, -1110, 0],
    [3, 0, -1, 0, -892, 3258],
    [2, 1, 1, 0, -810, 2616],
    [4, -1, -2, 0, 759, -1897],
    [0, 2, -1, 0, -713, -2117],
    [2, 2, -1, 0, -700, 2354],
    [2, 1, -2, 0, 691, 0],
    [2, -1, 0, -2, 596, 0],
    [4, 0, 1, 0, 549, -1423],
    [0, 0, 4, 0, 537, -1117],
    [4, -1, 0, 0, 520, -1571],
    [1, 0, -2, 0, -487, -1739],
    [2, 1, 0, -2, -399, 0],
    [0, 0, 2, -2, -381, -4421],
    [1, 1, 1, 0, 351, 0],
    [3, 0, -2, 0, -340, 0],
    [4, 0, -3, 0, 330, 0],
    [2, -1, 2, 0, 327, 0],
    [0, 2, 1, 0, -323, 1165],
    [1, 1, -1, 0, 299, 0],
    [2, 0, 3, 0, 294, 0],
    [2, 0, -1, -2, 0, 8752],
  ];

  // Meeus table 47.B: D, M, M', F, latitude (1e-6 deg).
  static const _b = <List<int>>[
    [0, 0, 0, 1, 5128122],
    [0, 0, 1, 1, 280602],
    [0, 0, 1, -1, 277693],
    [2, 0, 0, -1, 173237],
    [2, 0, -1, 1, 55413],
    [2, 0, -1, -1, 46271],
    [2, 0, 0, 1, 32573],
    [0, 0, 2, 1, 17198],
    [2, 0, 1, -1, 9266],
    [0, 0, 2, -1, 8822],
    [2, -1, 0, -1, 8216],
    [2, 0, -2, -1, 4324],
    [2, 0, 1, 1, 4200],
    [2, 1, 0, -1, -3359],
    [2, -1, -1, 1, 2463],
    [2, -1, 0, 1, 2211],
    [2, -1, -1, -1, 2065],
    [0, 1, -1, -1, -1870],
    [4, 0, -1, -1, 1828],
    [0, 1, 0, 1, -1794],
    [0, 0, 0, 3, -1749],
    [0, 1, -1, 1, -1565],
    [1, 0, 0, 1, -1491],
    [0, 1, 1, 1, -1475],
    [0, 1, 1, -1, -1410],
    [0, 1, 0, -1, -1344],
    [1, 0, 0, -1, -1335],
    [0, 0, 3, 1, 1107],
    [4, 0, 0, -1, 1021],
    [4, 0, -1, 1, 833],
  ];

  /// Geocentric Moon: longitude, latitude and distance.
  static MoonPosition moon(double jde, {bool withLatitude = true}) {
    final t = _centuries(jde);
    final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
    final lp = norm360(218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841 - t4 / 65194000);
    final d = norm360(297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868 - t4 / 113065000) * _rad;
    final m = norm360(357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000) * _rad;
    final mp = norm360(134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14712000) * _rad;
    final f = norm360(93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000 + t4 / 863310000) * _rad;
    final a1 = norm360(119.75 + 131.849 * t) * _rad;
    final a2 = norm360(53.09 + 479264.290 * t) * _rad;
    final a3 = norm360(313.45 + 481266.484 * t) * _rad;
    final e = 1 - 0.002516 * t - 0.0000074 * t2;
    final e2 = e * e;

    var sl = 0.0, sr = 0.0;
    for (final r in _lr) {
      final arg = r[0] * d + r[1] * m + r[2] * mp + r[3] * f;
      final ec = r[1] == 0 ? 1.0 : (r[1].abs() == 1 ? e : e2);
      if (r[4] != 0) sl += r[4] * ec * math.sin(arg);
      if (r[5] != 0) sr += r[5] * ec * math.cos(arg);
    }
    sl += 3958 * math.sin(a1) + 1962 * math.sin(lp * _rad - f) + 318 * math.sin(a2);

    var sb = 0.0;
    if (withLatitude) {
      for (final r in _b) {
        final arg = r[0] * d + r[1] * m + r[2] * mp + r[3] * f;
        final ec = r[1] == 0 ? 1.0 : (r[1].abs() == 1 ? e : e2);
        sb += r[4] * ec * math.sin(arg);
      }
      sb += -2235 * math.sin(lp * _rad) +
          382 * math.sin(a3) +
          175 * math.sin(a1 - f) +
          175 * math.sin(a1 + f) +
          127 * math.sin(lp * _rad - mp) -
          115 * math.sin(lp * _rad + mp);
    }
    return (lon: norm360(lp + sl / 1e6), lat: sb / 1e6, distance: 385000.56 + sr / 1000);
  }

  /// Mean Lahiri (Chitrapaksha) ayanamsa, degrees. Anchored to the
  /// published value 24.2288 (true) on 2026-02-15 and the definition of
  /// 23 deg 15' 00.658" on 1956-03-21, then carried by general precession.
  static double ayanamsa(double jde) {
    final t = _centuries(jde);
    return 23.8635 + (5028.796195 * t + 1.1054348 * t * t) / 3600;
  }

  /// Greenwich mean sidereal time in degrees at a UT Julian day.
  static double gmst(double jdUt) {
    final t = (jdUt - j2000) / 36525.0;
    return norm360(280.46061837 + 360.98564736629 * (jdUt - j2000) + 0.000387933 * t * t - t * t * t / 38710000);
  }

  /// Right ascension and declination (degrees) of an ecliptic position.
  static ({double ra, double dec}) toEquatorial(double lon, double lat, double jde) {
    final eps = obliquity(jde) * _rad;
    final l = lon * _rad, b = lat * _rad;
    final ra = math.atan2(math.sin(l) * math.cos(eps) - math.tan(b) * math.sin(eps), math.cos(l));
    final dec = math.asin(math.sin(b) * math.cos(eps) + math.cos(b) * math.sin(eps) * math.sin(l));
    return (ra: norm360(ra / _rad), dec: dec / _rad);
  }
}
