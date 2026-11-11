/// Summer-time rule of a city, from its country. The city list stores only
/// the standard offset, so the rule supplies the rest.
enum DstRule { none, eu, us, southAu, nz }

DateTime _nthSunday(int year, int month, int n) {
  // n >= 1: n-th Sunday; n == -1: last Sunday. Returns 00:00 UTC of that day.
  if (n > 0) {
    final first = DateTime.utc(year, month, 1);
    final shift = (DateTime.sunday - first.weekday) % 7;
    return DateTime.utc(year, month, 1 + shift + 7 * (n - 1));
  }
  final last = DateTime.utc(year, month + 1, 0);
  return DateTime.utc(year, month, last.day - last.weekday % 7);
}

/// A place on Earth with a time zone.
class Place {
  const Place({
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.standardOffsetMinutes,
  });

  final String name;

  /// State and/or country, shown under the name.
  final String region;
  final double latitude;
  final double longitude;

  /// Offset from UTC without summer time, minutes.
  final int standardOffsetMinutes;

  String get label => region.isEmpty ? name : '$name, $region';

  /// Same place seen from the engine's point of view. Two places with the
  /// same key give the same panchang.
  String get key => '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';

  DstRule get dstRule {
    if (region.contains('USA')) return region.contains('Arizona') ? DstRule.none : DstRule.us;
    if (region.contains('Canada')) return DstRule.us;
    if (region.contains('New Zealand')) return DstRule.nz;
    if (region.contains('Australia')) return name == 'Brisbane' || name == 'Perth' ? DstRule.none : DstRule.southAu;
    const eu = [
      'United Kingdom', 'Ireland', 'Portugal', 'France', 'Germany', 'Netherlands', 'Belgium', 'Switzerland',
      'Italy', 'Spain', 'Sweden', 'Norway', 'Denmark', 'Poland', 'Austria', 'Czechia', 'Finland', 'Greece',
    ];
    if (eu.any(region.contains)) return DstRule.eu;
    return DstRule.none;
  }

  /// UTC offset at an instant, including summer time.
  Duration offsetAt(DateTime utc) {
    final std = Duration(minutes: standardOffsetMinutes);
    final rule = dstRule;
    if (rule == DstRule.none) return std;
    final y = utc.toUtc().year;
    bool dst;
    switch (rule) {
      case DstRule.eu:
        final start = _nthSunday(y, 3, -1).add(const Duration(hours: 1));
        final end = _nthSunday(y, 10, -1).add(const Duration(hours: 1));
        dst = !utc.isBefore(start) && utc.isBefore(end);
      case DstRule.us:
        final start = _nthSunday(y, 3, 2).add(const Duration(hours: 2)) - std;
        final end = _nthSunday(y, 11, 1).add(const Duration(hours: 2)) - (std + const Duration(hours: 1));
        dst = !utc.isBefore(start) && utc.isBefore(end);
      case DstRule.southAu:
        final end = _nthSunday(y, 4, 1).add(const Duration(hours: 3)) - (std + const Duration(hours: 1));
        final start = _nthSunday(y, 10, 1).add(const Duration(hours: 2)) - std;
        dst = utc.isBefore(end) || !utc.isBefore(start);
      case DstRule.nz:
        final end = _nthSunday(y, 4, 1).add(const Duration(hours: 3)) - (std + const Duration(hours: 1));
        final start = _nthSunday(y, 9, -1).add(const Duration(hours: 2)) - std;
        dst = utc.isBefore(end) || !utc.isBefore(start);
      case DstRule.none:
        dst = false;
    }
    return dst ? std + const Duration(hours: 1) : std;
  }

  /// Wall-clock time at [utc]. The result is flagged UTC but its fields read
  /// as local time; use it only to show hours and dates.
  DateTime toLocal(DateTime utc) => utc.toUtc().add(offsetAt(utc));

  /// The instant at which the civil day [year]-[month]-[day] starts here.
  DateTime startOfDay(int year, int month, int day) {
    final naive = DateTime.utc(year, month, day);
    var t = naive - offsetAt(naive - Duration(minutes: standardOffsetMinutes));
    t = naive - offsetAt(t);
    return t;
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'region': region,
        'lat': latitude,
        'lon': longitude,
        'tz': standardOffsetMinutes,
      };

  static Place? fromJson(Object? j) {
    if (j is! Map) return null;
    final lat = (j['lat'] as num?)?.toDouble(), lon = (j['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return Place(
      name: j['name'] as String? ?? '',
      region: j['region'] as String? ?? '',
      latitude: lat,
      longitude: lon,
      standardOffsetMinutes: (j['tz'] as num?)?.toInt() ?? 330,
    );
  }

  /// New Delhi: the default place and the reference of the tests.
  static const newDelhi = Place(
    name: 'New Delhi',
    region: 'Delhi, India',
    latitude: 28.6139,
    longitude: 77.2090,
    standardOffsetMinutes: 330,
  );

  @override
  bool operator ==(Object other) => other is Place && other.key == key && other.name == name;

  @override
  int get hashCode => Object.hash(key, name);
}

extension on DateTime {
  DateTime operator -(Duration d) => subtract(d);
}
