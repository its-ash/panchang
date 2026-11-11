import '../app/app_model.dart';
import '../data/names.dart';
import '../engine/engine.dart';

/// Formatting of times and dates for the current place and language.
extension Formatting on AppModel {
  /// "6:59 AM". When the local date differs from [day] the date is added,
  /// as in "6:20 AM, 16 Feb".
  String clock(DateTime utc, {DateTime? day}) {
    final l = place.toLocal(utc);
    final h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final mm = l.minute.toString().padLeft(2, '0');
    final suffix = l.hour < 12 ? 'AM' : 'PM';
    final text = '$h12:$mm $suffix';
    if (day != null && (l.day != day.day || l.month != day.month)) {
      return '$text, ${l.day} ${bi(Names.monthNames[l.month - 1]).substring(0, hindi ? null : 3)}';
    }
    return text;
  }

  /// "6:59 AM - 7:44 AM".
  String range(TimeWindow w, {DateTime? day}) => '${clock(w.start, day: day)} - ${clock(w.end, day: day)}';

  /// "Sunday, 15 February 2026".
  String longDate(DateTime d) =>
      '${bi(Names.vaar[d.weekday]!).split(' ').first}, ${d.day} ${bi(Names.monthNames[d.month - 1])} ${d.year}';

  /// "February 2026".
  String monthYear(int year, int month) => '${bi(Names.monthNames[month - 1])} $year';

  /// "Trayodashi" / "Amavasya".
  String tithiName(int index) => bi(Names.tithiOf(index));

  /// "Krishna Paksha".
  String pakshaName(int tithiIndex) => bi(Names.paksha[tithiIndex < 15 ? 0 : 1]);

  /// "Krishna Trayodashi".
  String tithiWithPaksha(int index) {
    final p = index < 15 ? t('Shukla', 'शुक्ल') : t('Krishna', 'कृष्ण');
    return '$p ${tithiName(index)}';
  }

  /// "until 5:04 PM".
  String until(DateTime utc, {DateTime? day}) =>
      hindi ? '${clock(utc, day: day)} तक' : 'until ${clock(utc, day: day)}';
}
