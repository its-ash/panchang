import 'astro.dart';
import 'place.dart';
import 'sky.dart';

/// One stretch of a panchang element (a tithi, nakshatra, ...) with exact
/// start and end instants (UTC).
class Segment {
  const Segment(this.index, this.start, this.end);

  /// Zero-based index of the element: tithi 0..29 (0 = Shukla Pratipada,
  /// 14 = Purnima, 29 = Amavasya), nakshatra/yoga 0..26, karana 0..59,
  /// rashi 0..11.
  final int index;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  String toString() => 'Segment($index, $start .. $end)';
}

/// A lunar month: the stretch between two new moons (amanta).
class LunarMonth {
  const LunarMonth({required this.index, required this.adhika, required this.start, required this.end});

  /// 0 = Chaitra ... 11 = Phalguna.
  final int index;

  /// An extra month: no solar ingress (sankranti) falls inside it.
  final bool adhika;

  /// The new moons that start and end the month.
  final DateTime start;
  final DateTime end;
}

/// Conversions between times and the elements of the almanac.
abstract final class Elements {
  /// Nominal angular speeds in degrees per day, only used as first guesses.
  static const _tithiRate = 12.19, _moonRate = 13.18, _yogaRate = 14.2, _sunRate = 0.9856;

  /// Splits `[t0, t1]` into the stretches of an element driven by [angle].
  /// The first segment starts before [t0] (its true start) and the last
  /// ends after [t1] (its true end).
  static List<Segment> segments(
    double Function(double jd) angle,
    double span,
    int count,
    double rate,
    DateTime t0,
    DateTime t1,
  ) {
    final jd0 = Astro.julianDay(t0), jd1 = Astro.julianDay(t1);
    final a0 = angle(jd0);
    var k = (a0 / span).floor();
    var start = Sky.crossing(angle, k * span, jd0 - (a0 - k * span) / rate);
    final out = <Segment>[];
    while (true) {
      final end = Sky.crossing(angle, (k + 1) * span, start + span / rate);
      out.add(Segment(k % count, Astro.fromJulianDay(start), Astro.fromJulianDay(end)));
      if (end >= jd1) return out;
      start = end;
      k++;
    }
  }

  static List<Segment> tithis(DateTime t0, DateTime t1) => segments(Sky.elongation, 12, 30, _tithiRate, t0, t1);

  static List<Segment> karanas(DateTime t0, DateTime t1) => segments(Sky.elongation, 6, 60, _tithiRate, t0, t1);

  static List<Segment> nakshatras(DateTime t0, DateTime t1) =>
      segments(Sky.moonSidereal, 360 / 27, 27, _moonRate, t0, t1);

  static List<Segment> yogas(DateTime t0, DateTime t1) => segments(Sky.yogaAngle, 360 / 27, 27, _yogaRate, t0, t1);

  static List<Segment> moonRashis(DateTime t0, DateTime t1) => segments(Sky.moonSidereal, 30, 12, _moonRate, t0, t1);

  static List<Segment> sunRashis(DateTime t0, DateTime t1) => segments(Sky.sunSidereal, 30, 12, _sunRate, t0, t1);

  /// Tithi (0..29) running at an instant.
  static int tithiAt(DateTime t) => (Sky.elongation(Astro.julianDay(t)) / 12).floor() % 30;

  static int nakshatraAt(DateTime t) => (Sky.moonSidereal(Astro.julianDay(t)) / (360 / 27)).floor() % 27;

  static int moonRashiAt(DateTime t) => (Sky.moonSidereal(Astro.julianDay(t)) / 30).floor() % 12;

  static int sunRashiAt(DateTime t) => (Sky.sunSidereal(Astro.julianDay(t)) / 30).floor() % 12;

  /// The tithi segment that contains [t].
  static Segment tithiSegmentAt(DateTime t) {
    final i = tithiAt(t);
    final jd = Astro.julianDay(t);
    final a = Sky.elongation(jd);
    final start = Sky.crossing(Sky.elongation, i * 12.0, jd - (a - i * 12.0) / _tithiRate);
    final end = Sky.crossing(Sky.elongation, (i + 1) * 12.0, start + 12 / _tithiRate);
    return Segment(i, Astro.fromJulianDay(start), Astro.fromJulianDay(end));
  }

  /// First instant at or after [t] when the Moon-Sun elongation is a
  /// multiple of 360 degrees: the next new moon.
  static DateTime newMoonAfter(DateTime t) {
    final jd = Astro.julianDay(t);
    final a = Sky.elongation(jd);
    return Astro.fromJulianDay(Sky.crossing(Sky.elongation, 360, jd + (360 - a) / _tithiRate));
  }

  /// The latest new moon at or before [t].
  static DateTime newMoonBefore(DateTime t) {
    final jd = Astro.julianDay(t);
    final a = Sky.elongation(jd);
    return Astro.fromJulianDay(Sky.crossing(Sky.elongation, 0, jd - a / _tithiRate));
  }

  /// The lunar month that starts at the new moon [start].
  static LunarMonth lunarMonthFrom(DateTime start) {
    final end = newMoonAfter(start.add(const Duration(days: 1)));
    final s0 = (Sky.sunSidereal(Astro.julianDay(start)) / 30).floor() % 12;
    final s1 = (Sky.sunSidereal(Astro.julianDay(end)) / 30).floor() % 12;
    return LunarMonth(index: (s0 + 1) % 12, adhika: s0 == s1, start: start, end: end);
  }
}

/// The panchang of one civil day at one place, reckoned from sunrise to the
/// next sunrise, as in the traditional day.
class Panchang {
  Panchang._({
    required this.place,
    required this.year,
    required this.month,
    required this.day,
    required this.sunrise,
    required this.sunset,
    required this.nextSunrise,
    required this.moonrise,
    required this.moonset,
    required this.tithis,
    required this.nakshatras,
    required this.yogas,
    required this.karanas,
    required this.moonRashis,
    required this.sunRashis,
    required this.lunarMonth,
    required this.nextLunarMonth,
  });

  final Place place;
  final int year, month, day;

  /// Sunrise and sunset of this civil day; [nextSunrise] ends the panchang day.
  final DateTime sunrise, sunset, nextSunrise;

  /// Moonrise and moonset between this sunrise and the next; null when the
  /// Moon does not rise (or set) in that span.
  final DateTime? moonrise, moonset;

  /// Elements in force between sunrise and the next sunrise, in order. The
  /// first entry is the one at sunrise.
  final List<Segment> tithis, nakshatras, yogas, karanas, moonRashis, sunRashis;

  /// The amanta month the day belongs to, and the following one (which names
  /// the krishna paksha in the purnimanta scheme).
  final LunarMonth lunarMonth, nextLunarMonth;

  /// Weekday as [DateTime.weekday]: Monday 1 ... Sunday 7.
  int get weekday => DateTime.utc(year, month, day).weekday;

  Segment get tithi => tithis.first;
  Segment get nakshatra => nakshatras.first;
  Segment get yoga => yogas.first;
  Segment get karana => karanas.first;
  int get moonRashi => moonRashis.first.index;
  int get sunRashi => sunRashis.first.index;

  /// Shukla (waxing) paksha at sunrise.
  bool get isShukla => tithi.index < 15;

  /// Tithi number within its paksha, 1..15 (15 = Purnima or Amavasya).
  int get tithiInPaksha => tithi.index % 15 + 1;

  /// Month index 0..11 (Chaitra = 0) in the amanta scheme.
  int get amantaMonth => lunarMonth.index;

  /// Month index in the purnimanta scheme: the krishna paksha already
  /// belongs to the next month.
  int get purnimantaMonth => isShukla ? lunarMonth.index : nextLunarMonth.index;

  /// Adhika flag for the label in the chosen scheme.
  bool adhika({required bool purnimanta}) =>
      purnimanta && !isShukla ? nextLunarMonth.adhika : lunarMonth.adhika;

  /// Vikram Samvat (Chaitra-start, the common northern and western count).
  int get vikramSamvat => _vikram(year, month, lunarMonth.index);

  int get shakaSamvat => vikramSamvat - 135;

  /// Season by the Sun's sidereal sign: 0 Vasanta, 1 Grishma, 2 Varsha,
  /// 3 Sharad, 4 Hemanta, 5 Shishira.
  int get ritu => ((sunRashi + 1) % 12) ~/ 2;

  /// True for Uttarayana (Sun from sidereal Makara to Karka).
  bool get uttarayana => const {9, 10, 11, 0, 1, 2}.contains(sunRashi);

  static int _vikram(int y, int m, int lunarIndex) => lunarIndex >= 9 && m <= 4 ? y + 56 : y + 57;

  /// Computes the panchang of the civil day [year]-[month]-[day] at [place].
  factory Panchang.compute(Place place, int year, int month, int day) {
    final today = Sky.sun(place, year, month, day);
    final next = DateTime.utc(year, month, day).add(const Duration(days: 1));
    final tomorrow = Sky.sun(place, next.year, next.month, next.day);
    // Polar day or night: fall back to 06:00 and 18:00 local time.
    final start = place.startOfDay(year, month, day);
    final sunrise = today.rise ?? start.add(const Duration(hours: 6));
    final sunset = today.set ?? start.add(const Duration(hours: 18));
    final nextSunrise = tomorrow.rise ?? start.add(const Duration(hours: 30));
    final moon = Sky.moon(place, sunrise, nextSunrise);
    final nm0 = Elements.newMoonBefore(sunrise);
    final month0 = Elements.lunarMonthFrom(nm0);
    return Panchang._(
      place: place,
      year: year,
      month: month,
      day: day,
      sunrise: sunrise,
      sunset: sunset,
      nextSunrise: nextSunrise,
      moonrise: moon.rise,
      moonset: moon.set,
      tithis: Elements.tithis(sunrise, nextSunrise),
      nakshatras: Elements.nakshatras(sunrise, nextSunrise),
      yogas: Elements.yogas(sunrise, nextSunrise),
      karanas: Elements.karanas(sunrise, nextSunrise),
      moonRashis: Elements.moonRashis(sunrise, nextSunrise),
      sunRashis: Elements.sunRashis(sunrise, nextSunrise),
      lunarMonth: month0,
      nextLunarMonth: Elements.lunarMonthFrom(month0.end),
    );
  }

  /// A lightweight version for month grids: sunrise and the tithi at
  /// sunrise with its end, without the other elements.
  static ({DateTime sunrise, Segment tithi}) quick(Place place, int year, int month, int day) {
    final sunrise = Sky.sun(place, year, month, day).rise ?? place.startOfDay(year, month, day).add(const Duration(hours: 6));
    return (sunrise: sunrise, tithi: Elements.tithiSegmentAt(sunrise));
  }
}
