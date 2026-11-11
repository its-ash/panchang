import 'package:flutter_test/flutter_test.dart';
import 'package:panchang/engine/engine.dart';

/// Reference: Drik Panchang day pages for New Delhi
/// (https://www.drikpanchang.com/panchang/day-panchang.html?geoname-id=1261481&date=DD/MM/YYYY),
/// which use Lahiri ayanamsa, Swiss Ephemeris and sunrise of the upper limb.
/// Drik shows whole minutes. Measured on these 13 dates: sunrise/sunset within
/// 0.5 min, moonrise/moonset within 0.5 min, tithi/nakshatra/yoga end times
/// within 2.2 min (ours are consistently about 1.3 min later). The tolerances
/// below leave a little room on top of that.
const delhi = Place(
  name: 'New Delhi',
  region: 'Delhi, India',
  latitude: 28.6356, // 28 deg 38' 08" N, as on the Drik page
  longitude: 77.2244, // 77 deg 13' 28" E
  standardOffsetMinutes: 330,
);

/// A local clock time on the civil day [d], with `+1` for the next day.
DateTime at(DateTime d, String hhmm, {int plusDays = 0}) {
  final p = hhmm.split(':');
  return DateTime.utc(d.year, d.month, d.day + plusDays, int.parse(p[0]), int.parse(p[1]));
}

double minutesOff(Place p, DateTime? actual, DateTime expectedLocal) {
  if (actual == null) return double.infinity;
  return p.toLocal(actual).difference(expectedLocal).inSeconds / 60.0;
}

class Ref {
  const Ref(this.date, this.sunrise, this.sunset, this.tithi, this.tithiEnd, this.nak, this.nakEnd, this.yoga, this.yogaEnd,
      {this.moonrise, this.moonset, this.nakEndNext = false});
  final DateTime date;
  final String sunrise, sunset;
  final int tithi; // 0-based
  final String tithiEnd; // local, may be next day (see tithiNext)
  final int nak;
  final String nakEnd;
  final int yoga;
  final String yogaEnd;
  final (String, int)? moonrise, moonset; // time, day offset
  final bool nakEndNext;
}

final refs = <Ref>[
  Ref(DateTime.utc(2026, 2, 15), '07:00', '18:11', 27, '17:04', 20, '19:48', 16, '26:47',
      moonrise: ('06:20', 1), moonset: ('16:03', 0)),
  Ref(DateTime.utc(2026, 2, 16), '06:59', '18:12', 28, '17:34', 21, '20:47', 17, '25:50',
      moonrise: ('06:55', 1), moonset: ('17:04', 0)),
  Ref(DateTime.utc(2026, 2, 17), '06:58', '18:13', 29, '17:30', 22, '21:16', 18, '24:29', moonset: ('18:05', 0)),
  Ref(DateTime.utc(2026, 2, 18), '06:57', '18:13', 0, '16:57', 23, '21:16', 19, '22:45',
      moonrise: ('07:27', 0), moonset: ('19:05', 0)),
  Ref(DateTime.utc(2026, 2, 19), '06:56', '18:14', 1, '15:58', 24, '20:52', 20, '20:42',
      moonrise: ('07:58', 0), moonset: ('20:06', 0)),
  Ref(DateTime.utc(2026, 2, 20), '06:55', '18:15', 2, '14:38', 25, '20:07', 21, '18:23',
      moonrise: ('08:29', 0), moonset: ('21:08', 0)),
  Ref(DateTime.utc(2026, 2, 21), '06:54', '18:15', 3, '13:00', 26, '19:07', 22, '15:51',
      moonrise: ('09:01', 0), moonset: ('22:11', 0)),
  Ref(DateTime.utc(2025, 10, 20), '06:25', '17:46', 28, '15:44', 12, '20:17', 26, '26:35',
      moonrise: ('06:11', 1), moonset: ('16:56', 0)),
  Ref(DateTime.utc(2026, 6, 15), '05:23', '19:20', 29, '08:23', 4, '19:08', 8, '08:56', moonset: ('19:53', 0)),
  Ref(DateTime.utc(2026, 9, 10), '06:03', '18:32', 28, '10:33', 9, '14:04', 20, '19:17', moonset: ('17:58', 0)),
  Ref(DateTime.utc(2026, 12, 1), '06:56', '17:24', 22, '23:13', 9, '09:00', 26, '12:15',
      moonrise: ('00:42', 1), moonset: ('12:33', 0)),
  Ref(DateTime.utc(2026, 3, 4), '06:43', '18:23', 15, '16:48', 10, '07:39', 7, '08:52',
      moonrise: ('19:24', 0), moonset: ('06:59', 0)),
  Ref(DateTime.utc(2025, 8, 16), '05:51', '18:59', 22, '21:34', 1, '06:06', 10, '07:21',
      moonrise: ('23:37', 0), moonset: ('12:57', 0)),
];

/// "HH:MM" where HH may exceed 23 (next day).
DateTime clock(DateTime d, String t) {
  final p = t.split(':');
  return DateTime.utc(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
}

void main() {
  group('rise and set against Drik Panchang (New Delhi)', () {
    for (final r in refs) {
      test('${r.date.toIso8601String().substring(0, 10)} sunrise/sunset/moonrise/moonset', () {
        final p = Panchang.compute(delhi, r.date.year, r.date.month, r.date.day);
        expect(minutesOff(delhi, p.sunrise, clock(r.date, r.sunrise)).abs(), lessThanOrEqualTo(1.0), reason: 'sunrise');
        expect(minutesOff(delhi, p.sunset, clock(r.date, r.sunset)).abs(), lessThanOrEqualTo(1.0), reason: 'sunset');
        if (r.moonrise case (final t, final plus)) {
          expect(minutesOff(delhi, p.moonrise, at(r.date, t, plusDays: plus)).abs(), lessThanOrEqualTo(1.5), reason: 'moonrise');
        }
        if (r.moonset case (final t, final plus)) {
          expect(minutesOff(delhi, p.moonset, at(r.date, t, plusDays: plus)).abs(), lessThanOrEqualTo(1.5), reason: 'moonset');
        }
      });
    }
  });

  group('tithi, nakshatra, yoga at sunrise and their end times', () {
    for (final r in refs) {
      test(r.date.toIso8601String().substring(0, 10), () {
        final p = Panchang.compute(delhi, r.date.year, r.date.month, r.date.day);
        expect(p.tithi.index, r.tithi, reason: 'tithi');
        expect(minutesOff(delhi, p.tithi.end, clock(r.date, r.tithiEnd)).abs(), lessThanOrEqualTo(3.0), reason: 'tithi end');
        expect(p.nakshatra.index, r.nak, reason: 'nakshatra');
        expect(minutesOff(delhi, p.nakshatra.end, clock(r.date, r.nakEnd)).abs(), lessThanOrEqualTo(3.0), reason: 'nakshatra end');
        expect(p.yoga.index, r.yoga, reason: 'yoga');
        expect(minutesOff(delhi, p.yoga.end, clock(r.date, r.yogaEnd)).abs(), lessThanOrEqualTo(4.0), reason: 'yoga end');
      });
    }
  });
}
