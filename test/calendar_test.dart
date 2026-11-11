import 'package:flutter_test/flutter_test.dart';
import 'package:panchang/data/names.dart';
import 'package:panchang/engine/engine.dart';

import 'engine_test.dart' show delhi, at, minutesOff;

Panchang day(int y, int m, int d) => Panchang.compute(delhi, y, m, d);

void expectWindow(String label, TimeWindow? w, String from, String to, DateTime date, {int endPlus = 0, double tol = 2.0}) {
  expect(w, isNotNull, reason: label);
  expect(minutesOff(delhi, w!.start, at(date, from)).abs(), lessThanOrEqualTo(tol), reason: '$label start');
  expect(minutesOff(delhi, w.end, at(date, to, plusDays: endPlus)).abs(), lessThanOrEqualTo(tol), reason: '$label end');
}

Muhurat muhurat(Panchang p) =>
    Muhurat.compute(sunrise: p.sunrise, sunset: p.sunset, nextSunrise: p.nextSunrise, weekday: p.weekday);

void main() {
  // Reference: Drik Panchang, New Delhi (see engine_test.dart).
  group('muhurat timings', () {
    test('Sunday 2026-02-15', () {
      final d = DateTime.utc(2026, 2, 15);
      final mu = muhurat(day(2026, 2, 15));
      expectWindow('rahu', mu.rahuKaal, '16:47', '18:11', d);
      expectWindow('yamaganda', mu.yamaganda, '12:35', '13:59', d);
      expectWindow('gulika', mu.gulikaKaal, '15:23', '16:47', d);
      expectWindow('abhijit', mu.abhijit, '12:13', '12:58', d);
      expectWindow('brahma', mu.brahma, '05:17', '06:08', d);
      expect(mu.durMuhurat, hasLength(1));
      expectWindow('dur', mu.durMuhurat.single, '16:42', '17:26', d);
    });

    test('Monday 2026-02-16', () {
      final d = DateTime.utc(2026, 2, 16);
      final mu = muhurat(day(2026, 2, 16));
      expectWindow('rahu', mu.rahuKaal, '08:23', '09:47', d);
      expectWindow('yamaganda', mu.yamaganda, '11:11', '12:35', d);
      expectWindow('gulika', mu.gulikaKaal, '13:59', '15:24', d);
      expectWindow('dur 1', mu.durMuhurat[0], '12:58', '13:43', d);
      expectWindow('dur 2', mu.durMuhurat[1], '15:12', '15:57', d);
    });

    test('Tuesday 2026-02-17 has a night Dur Muhurat', () {
      final d = DateTime.utc(2026, 2, 17);
      final mu = muhurat(day(2026, 2, 17));
      expectWindow('rahu', mu.rahuKaal, '15:24', '16:48', d);
      expectWindow('dur day', mu.durMuhurat[0], '09:13', '09:58', d);
      expectWindow('dur night', mu.durMuhurat[1], '23:18', '00:09', d, endPlus: 1);
    });

    test('Wednesday 2026-02-18: no Abhijit, Dur Muhurat at midday', () {
      final d = DateTime.utc(2026, 2, 18);
      final mu = muhurat(day(2026, 2, 18));
      expect(mu.abhijit, isNull);
      expectWindow('dur', mu.durMuhurat.single, '12:13', '12:58', d);
    });

    test('Thursday, Friday, Saturday', () {
      final thu = muhurat(day(2026, 2, 19));
      expectWindow('thu dur 1', thu.durMuhurat[0], '10:42', '11:27', DateTime.utc(2026, 2, 19));
      expectWindow('thu dur 2', thu.durMuhurat[1], '15:13', '15:58', DateTime.utc(2026, 2, 19));
      final fri = muhurat(day(2026, 2, 20));
      expectWindow('fri dur 1', fri.durMuhurat[0], '09:11', '09:56', DateTime.utc(2026, 2, 20));
      expectWindow('fri dur 2', fri.durMuhurat[1], '12:58', '13:43', DateTime.utc(2026, 2, 20));
      final sat = muhurat(day(2026, 2, 21));
      expectWindow('sat gulika', sat.gulikaKaal, '06:54', '08:19', DateTime.utc(2026, 2, 21));
      expectWindow('sat dur', sat.durMuhurat.single, '06:54', '08:25', DateTime.utc(2026, 2, 21));
    });

    test('choghadiya: 16 parts that tile day and night', () {
      final p = day(2026, 2, 15);
      final mu = muhurat(p);
      expect(mu.choghadiya, hasLength(16));
      expect(mu.choghadiya.first.window.start, p.sunrise);
      expect(mu.choghadiya[7].window.end, p.sunset);
      expect(mu.choghadiya.last.window.end, p.nextSunrise);
      // Sunday starts with Udveg, the night with Shubh.
      expect(Names.choghadiya[mu.choghadiya[0].kind].en, 'Udveg');
      expect(Names.choghadiya[mu.choghadiya[8].kind].en, 'Shubh');
      // Monday starts with Amrit.
      expect(Names.choghadiya[muhurat(day(2026, 2, 16)).choghadiya[0].kind].en, 'Amrit');
    });
  });

  group('month, year and the other elements', () {
    test('lunar months, amanta and purnimanta', () {
      // Drik Panchang: (date, amanta, purnimanta, adhika).
      final cases = <(DateTime, int, int, bool)>[
        (DateTime.utc(2026, 2, 15), 10, 11, false), // Magha / Phalguna
        (DateTime.utc(2026, 2, 18), 11, 11, false), // Phalguna both
        (DateTime.utc(2026, 3, 4), 11, 0, false), // Phalguna / Chaitra
        (DateTime.utc(2026, 6, 15), 2, 2, true), // Adhika Jyeshtha
        (DateTime.utc(2026, 9, 10), 4, 5, false), // Shravana / Bhadrapada
        (DateTime.utc(2025, 10, 20), 6, 7, false), // Ashwin / Kartika
        (DateTime.utc(2025, 8, 16), 4, 5, false), // Shravana / Bhadrapada
        (DateTime.utc(2026, 12, 1), 7, 8, false), // Kartika / Margashirsha
      ];
      for (final (d, amanta, purni, adhika) in cases) {
        final p = day(d.year, d.month, d.day);
        expect(p.amantaMonth, amanta, reason: '$d amanta');
        expect(p.purnimantaMonth, purni, reason: '$d purnimanta');
        expect(p.lunarMonth.adhika, adhika, reason: '$d adhika');
      }
    });

    test('Vikram and Shaka samvat', () {
      expect(day(2026, 2, 15).vikramSamvat, 2082);
      expect(day(2026, 2, 15).shakaSamvat, 1947);
      expect(day(2026, 3, 4).vikramSamvat, 2082); // before Chaitra Shukla Pratipada
      expect(day(2026, 6, 15).vikramSamvat, 2083);
      expect(day(2026, 6, 15).shakaSamvat, 1948);
      expect(day(2025, 10, 20).vikramSamvat, 2082);
      expect(day(2026, 12, 1).vikramSamvat, 2083);
    });

    test('moon sign and sun sign changes', () {
      final feb17 = day(2026, 2, 17); // Makara until 09:05, then Kumbha
      expect(feb17.moonRashis.map((s) => s.index), [9, 10]);
      expect(minutesOff(delhi, feb17.moonRashis[1].start, at(DateTime.utc(2026, 2, 17), '09:05')).abs(), lessThanOrEqualTo(3));
      final feb19 = day(2026, 2, 19); // Kumbha until 15:00, then Meena
      expect(feb19.moonRashis.map((s) => s.index), [10, 11]);
      expect(minutesOff(delhi, feb19.moonRashis[1].start, at(DateTime.utc(2026, 2, 19), '15:00')).abs(), lessThanOrEqualTo(3));
      final aug16 = day(2025, 8, 16); // Sun Karka until 02:00 on 17th, then Simha
      expect(aug16.sunRashis.map((s) => s.index), [3, 4]);
      expect(minutesOff(delhi, aug16.sunRashis[1].start, at(DateTime.utc(2025, 8, 16), '02:00', plusDays: 1)).abs(), lessThanOrEqualTo(3));
    });

    test('karanas and names', () {
      final p = day(2026, 2, 15); // Vanija until 17:04, then Vishti
      expect(p.karanas.map((s) => Names.karana(s.index).en).take(2), ['Vanija', 'Vishti (Bhadra)']);
      final feb16 = day(2026, 2, 16); // Shakuni, Chatushpada, Naga
      expect(feb16.karanas.map((s) => Names.karana(s.index).en), ['Shakuni', 'Chatushpada', 'Naga']);
      expect(Names.tithiOf(14).en, 'Purnima');
      expect(Names.tithiOf(29).en, 'Amavasya');
      expect(Names.yoga[16].en, 'Vyatipata');
      expect(Names.nakshatra[20].hi, 'उत्तराषाढ़ा');
    });

    test('ritu and ayana', () {
      expect(Names.ritu[day(2026, 2, 15).ritu].en, startsWith('Shishira'));
      expect(day(2026, 2, 15).uttarayana, isTrue);
      expect(day(2026, 9, 10).uttarayana, isFalse);
      expect(Names.ritu[day(2026, 9, 10).ritu].en, startsWith('Varsha'));
    });
  });

  group('places and time zones', () {
    const london = Place(name: 'London', region: 'United Kingdom', latitude: 51.51, longitude: -0.13, standardOffsetMinutes: 0);
    const newYork = Place(name: 'New York', region: 'New York, USA', latitude: 40.71, longitude: -74.01, standardOffsetMinutes: -300);
    const sydney = Place(name: 'Sydney', region: 'Australia', latitude: -33.87, longitude: 151.21, standardOffsetMinutes: 600);

    test('summer time rules', () {
      expect(london.toLocal(DateTime.utc(2026, 7, 1, 12)).hour, 13);
      expect(london.toLocal(DateTime.utc(2026, 1, 1, 12)).hour, 12);
      expect(london.toLocal(DateTime.utc(2026, 3, 29, 0, 59)).hour, 0); // before the switch
      expect(london.toLocal(DateTime.utc(2026, 3, 29, 1, 0)).hour, 2);
      expect(newYork.toLocal(DateTime.utc(2026, 7, 1, 12)).hour, 8);
      expect(newYork.toLocal(DateTime.utc(2026, 1, 5, 12)).hour, 7);
      expect(sydney.toLocal(DateTime.utc(2026, 1, 1, 0)).hour, 11);
      expect(sydney.toLocal(DateTime.utc(2026, 7, 1, 0)).hour, 10);
      expect(delhi.toLocal(DateTime.utc(2026, 7, 1, 0)).hour, 5);
    });

    test('start of a civil day', () {
      expect(delhi.startOfDay(2026, 2, 15), DateTime.utc(2026, 2, 14, 18, 30));
      expect(london.startOfDay(2026, 7, 1), DateTime.utc(2026, 6, 30, 23));
      expect(newYork.startOfDay(2026, 1, 5), DateTime.utc(2026, 1, 5, 5));
    });

    test('panchang works abroad: London sunrise in June is about 04:45 BST', () {
      final p = Panchang.compute(london, 2026, 6, 21);
      final rise = london.toLocal(p.sunrise);
      expect(rise.hour, 4);
      expect(rise.minute, inInclusiveRange(40, 50));
      final set = london.toLocal(p.sunset);
      expect(set.hour, 21);
    });
  });
}
