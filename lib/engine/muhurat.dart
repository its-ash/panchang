/// A span of time (UTC instants).
class TimeWindow {
  const TimeWindow(this.start, this.end);

  final DateTime start, end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  Duration get length => end.difference(start);
}

/// One choghadiya: eight equal parts of the day and eight of the night.
class Choghadiya {
  const Choghadiya(this.kind, this.window, {required this.isDay});

  /// 0 Udveg, 1 Chal, 2 Labh, 3 Amrit, 4 Kaal, 5 Shubh, 6 Rog.
  final int kind;
  final TimeWindow window;
  final bool isDay;

  /// Amrit, Shubh and Labh are favourable, Chal is mixed, the rest are not.
  bool get isAuspicious => kind == 2 || kind == 3 || kind == 5;
}

/// Daily timings that depend only on sunrise, sunset and the weekday.
///
/// Rahu Kaal, Yamaganda and Gulika Kaal are one eighth of the daytime, at
/// the position given by the weekday tables below. Abhijit is the 8th of the
/// 15 muhurtas of the day (not kept on Wednesday). Brahma Muhurat is the
/// 14th of the 15 muhurtas of the night, i.e. from two muhurtas to one
/// muhurta before sunrise. Dur Muhurat follows the weekday table of day
/// muhurtas used by Drik Panchang, plus Tuesday's 7th night muhurta.
class Muhurat {
  Muhurat._({
    required this.rahuKaal,
    required this.yamaganda,
    required this.gulikaKaal,
    required this.abhijit,
    required this.brahma,
    required this.durMuhurat,
    required this.choghadiya,
  });

  final TimeWindow rahuKaal, yamaganda, gulikaKaal, brahma;

  /// Null on Wednesday, when Abhijit is not observed.
  final TimeWindow? abhijit;
  final List<TimeWindow> durMuhurat;

  /// Day choghadiyas followed by night choghadiyas.
  final List<Choghadiya> choghadiya;

  // Part (1..8) of the daytime, by weekday Monday = 1 ... Sunday = 7.
  static const _rahu = {1: 2, 2: 7, 3: 5, 4: 6, 5: 4, 6: 3, 7: 8};
  static const _yama = {1: 4, 2: 3, 3: 2, 4: 1, 5: 7, 6: 6, 7: 5};
  static const _gulika = {1: 6, 2: 5, 3: 4, 4: 3, 5: 2, 6: 1, 7: 7};

  // Dur Muhurat: 15ths of the day (1..15), and Tuesday's 7th 15th of the night.
  static const _dur = {
    1: [9, 12],
    2: [4],
    3: [8],
    4: [6, 12],
    5: [4, 9],
    6: [1, 2],
    7: [14],
  };

  // First day choghadiya by weekday; each next one follows the cycle
  // Udveg, Chal, Labh, Amrit, Kaal, Shubh, Rog.
  static const _dayStart = {7: 0, 1: 3, 2: 6, 3: 2, 4: 5, 5: 1, 6: 4};

  /// [weekday] is [DateTime.weekday] of the civil day; [nextSunrise] ends the night.
  factory Muhurat.compute({
    required DateTime sunrise,
    required DateTime sunset,
    required DateTime nextSunrise,
    required int weekday,
  }) {
    final day = sunset.difference(sunrise);
    final night = nextSunrise.difference(sunset);
    DateTime at(DateTime from, Duration span, int parts, double part) =>
        from.add(Duration(microseconds: (span.inMicroseconds * part / parts).round()));
    TimeWindow dayPart(int n) => TimeWindow(at(sunrise, day, 8, n - 1.0), at(sunrise, day, 8, n.toDouble()));
    TimeWindow day15(int n) => TimeWindow(at(sunrise, day, 15, n - 1.0), at(sunrise, day, 15, n.toDouble()));

    final dur = <TimeWindow>[for (final n in _dur[weekday]!) day15(n)];
    // Merge touching windows (Saturday's 1st and 2nd).
    for (var i = dur.length - 1; i > 0; i--) {
      if (dur[i].start == dur[i - 1].end) {
        dur[i - 1] = TimeWindow(dur[i - 1].start, dur[i].end);
        dur.removeAt(i);
      }
    }
    if (weekday == DateTime.tuesday) {
      dur.add(TimeWindow(at(sunset, night, 15, 6), at(sunset, night, 15, 7)));
    }

    final first = _dayStart[weekday]!;
    final choghadiya = <Choghadiya>[
      for (var i = 0; i < 8; i++) Choghadiya((first + i) % 7, dayPart(i + 1), isDay: true),
      for (var i = 0; i < 8; i++)
        Choghadiya(
          (first + 5 + i) % 7,
          TimeWindow(at(sunset, night, 8, i.toDouble()), at(sunset, night, 8, i + 1.0)),
          isDay: false,
        ),
    ];

    return Muhurat._(
      rahuKaal: dayPart(_rahu[weekday]!),
      yamaganda: dayPart(_yama[weekday]!),
      gulikaKaal: dayPart(_gulika[weekday]!),
      abhijit: weekday == DateTime.wednesday ? null : day15(8),
      brahma: TimeWindow(sunrise.subtract(night * 2 ~/ 15), sunrise.subtract(night ~/ 15)),
      durMuhurat: dur,
      choghadiya: choghadiya,
    );
  }
}
