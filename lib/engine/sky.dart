import 'dart:math' as math;

import 'astro.dart';
import 'place.dart';

const double _rad = math.pi / 180;

/// Rising and setting of a body on one civil day.
typedef RiseSet = ({DateTime? rise, DateTime? set});

/// Time-dependent quantities of the panchang, as functions of UT Julian day,
/// and the root finders that turn them into instants.
abstract final class Sky {
  /// Elongation of the Moon from the Sun, degrees (0 = new moon).
  static double elongation(double jd) {
    final j = Astro.jde(jd);
    return norm360(Astro.moon(j, withLatitude: false).lon - Astro.sun(j).lon);
  }

  static double sunSidereal(double jd) {
    final j = Astro.jde(jd);
    return norm360(Astro.sun(j).lon - Astro.ayanamsa(j));
  }

  static double moonSidereal(double jd) {
    final j = Astro.jde(jd);
    return norm360(Astro.moon(j, withLatitude: false).lon - Astro.ayanamsa(j));
  }

  /// Sum of sidereal longitudes of Sun and Moon (drives the yoga).
  static double yogaAngle(double jd) {
    final j = Astro.jde(jd);
    final ay = Astro.ayanamsa(j);
    return norm360(Astro.sun(j).lon + Astro.moon(j, withLatitude: false).lon - 2 * ay);
  }

  /// The instant, near [jdGuess], at which [angle] (increasing with time,
  /// degrees) equals [target]. Newton steps on a numerical derivative; the
  /// guess must be less than half a turn away in angle.
  static double crossing(double Function(double jd) angle, double target, double jdGuess) {
    var t = jdGuess;
    for (var i = 0; i < 12; i++) {
      final d = angleDiff(target, angle(t));
      final rate = angleDiff(angle(t + 0.005), angle(t - 0.005)) / 0.01;
      if (rate <= 0) break;
      final step = d / rate;
      t += step;
      if (step.abs() < 2e-8) break; // under 2 ms
    }
    return t;
  }

  /// Altitude of the centre of a body above the horizon, degrees.
  static double _altitude(double jd, double lat, double lon, bool isMoon, [List<double>? h0Out]) {
    final j = Astro.jde(jd);
    double ra, dec;
    if (isMoon) {
      final m = Astro.moon(j);
      final eq = Astro.toEquatorial(m.lon, m.lat, j);
      ra = eq.ra;
      dec = eq.dec;
      if (h0Out != null) {
        final parallax = math.asin(6378.14 / m.distance) / _rad;
        // Drik Panchang convention: the centre of the disc on the true
        // horizon, seen from the surface (so the geocentric altitude equals
        // the horizontal parallax). Checked against its published times.
        h0Out[0] = parallax;
      }
    } else {
      final s = Astro.sun(j);
      final eq = Astro.toEquatorial(s.lon, 0, j);
      ra = eq.ra;
      dec = eq.dec;
      if (h0Out != null) h0Out[0] = -0.8333;
    }
    final h = (Astro.gmst(jd) + lon - ra) * _rad;
    final phi = lat * _rad, d = dec * _rad;
    final sinAlt = math.sin(phi) * math.sin(d) + math.cos(phi) * math.cos(d) * math.cos(h);
    return math.asin(sinAlt.clamp(-1.0, 1.0)) / _rad;
  }

  static double _margin(double jd, double lat, double lon, bool isMoon) {
    final h0 = [0.0];
    final alt = _altitude(jd, lat, lon, isMoon, h0);
    return alt - h0[0];
  }

  /// First rising and setting of the Sun or Moon in `[start, end)`
  /// (default: 24 hours). The Sun's upper limb is taken at -0.8333 deg
  /// (refraction 34' plus semi-diameter 16'); the Moon's centre at the
  /// horizon after parallax (see `_altitude`). Returns null
  /// for an event that does not happen in that window (polar day, a day
  /// without moonrise).
  static RiseSet riseSet(DateTime start, Place place, {required bool moon, DateTime? end}) {
    final jd0 = Astro.julianDay(start);
    const step = 1 / 144.0; // 10 minutes
    final steps = end == null ? 144 : ((Astro.julianDay(end) - jd0) / step).ceil();
    DateTime? rise, set;
    var prevT = jd0;
    var prev = _margin(prevT, place.latitude, place.longitude, moon);
    for (var i = 1; i <= steps && (rise == null || set == null); i++) {
      final t = jd0 + i * step;
      final cur = _margin(t, place.latitude, place.longitude, moon);
      if (prev < 0 && cur >= 0 && rise == null) {
        rise = Astro.fromJulianDay(_bisect(prevT, t, place, moon));
      } else if (prev > 0 && cur <= 0 && set == null) {
        set = Astro.fromJulianDay(_bisect(prevT, t, place, moon));
      }
      prevT = t;
      prev = cur;
    }
    return (rise: rise, set: set);
  }

  static double _bisect(double a, double b, Place p, bool moon) {
    var fa = _margin(a, p.latitude, p.longitude, moon);
    for (var i = 0; i < 28; i++) {
      final m = (a + b) / 2;
      final fm = _margin(m, p.latitude, p.longitude, moon);
      if ((fa < 0) == (fm < 0)) {
        a = m;
        fa = fm;
      } else {
        b = m;
      }
    }
    return (a + b) / 2;
  }

  /// Sunrise and sunset of a civil day at [place].
  static RiseSet sun(Place place, int year, int month, int day) =>
      riseSet(place.startOfDay(year, month, day), place, moon: false);

  /// Moonrise and moonset between two sunrises (the panchang day), as Drik
  /// Panchang and printed almanacs list them.
  static RiseSet moon(Place place, DateTime sunrise, DateTime nextSunrise) =>
      riseSet(sunrise, place, moon: true, end: nextSunrise);
}
