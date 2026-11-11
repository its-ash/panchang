import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/names.dart';
import '../engine/engine.dart';

/// App state: language, month system, place and the selected date. Saved in
/// `shared_preferences`.
class AppModel extends ChangeNotifier {
  AppModel._(this._prefs, this._hindi, this._purnimanta, this._place);

  final SharedPreferences _prefs;
  bool _hindi;
  bool _purnimanta;
  Place _place;

  late DateTime _date = _today();

  static Future<AppModel> load([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    Place? place;
    final raw = p.getString('place');
    if (raw != null) {
      try {
        place = Place.fromJson(jsonDecode(raw));
      } on FormatException {
        place = null;
      }
    }
    return AppModel._(p, p.getBool('hindi') ?? false, p.getBool('purnimanta') ?? false, place ?? Place.newDelhi);
  }

  bool get hindi => _hindi;
  bool get purnimanta => _purnimanta;
  Place get place => _place;

  /// The selected civil date (fields of a UTC DateTime at midnight).
  DateTime get date => _date;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime.utc(n.year, n.month, n.day);
  }

  set hindi(bool v) {
    if (v == _hindi) return;
    _hindi = v;
    _prefs.setBool('hindi', v);
    notifyListeners();
  }

  set purnimanta(bool v) {
    if (v == _purnimanta) return;
    _purnimanta = v;
    _prefs.setBool('purnimanta', v);
    notifyListeners();
  }

  set place(Place v) {
    _place = v;
    _prefs.setString('place', jsonEncode(v.toJson()));
    notifyListeners();
  }

  set date(DateTime v) {
    final d = DateTime.utc(v.year, v.month, v.day);
    if (d == _date) return;
    _date = d;
    notifyListeners();
  }

  void shiftDays(int n) => date = DateTime.utc(_date.year, _date.month, _date.day + n);

  void goToday() => date = _today();

  bool get isToday => _date == _today();

  // ---- translation helpers ------------------------------------------------

  /// English or Hindi text, depending on the setting.
  String t(String en, String hi) => _hindi ? hi : en;

  String bi(Bi b) => b.of(_hindi);

  // ---- panchang cache -----------------------------------------------------

  final _cache = <String, Panchang>{};

  /// The (cached) panchang of a civil date at the current place.
  Panchang panchangFor(DateTime d) {
    final key = '${_place.key}|${d.year}-${d.month}-${d.day}';
    if (_cache.length > 90) _cache.clear();
    return _cache.putIfAbsent(key, () => Panchang.compute(_place, d.year, d.month, d.day));
  }

  Panchang get panchang => panchangFor(_date);

  /// Hindu month label such as "Phalguna" or "Adhika Jyeshtha".
  String monthLabel(Panchang p) {
    final idx = _purnimanta ? p.purnimantaMonth : p.amantaMonth;
    final name = bi(Names.month[idx]);
    return p.adhika(purnimanta: _purnimanta) ? '${t('Adhika', 'अधिक')} $name' : name;
  }
}

/// Makes the [AppModel] available below it and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppModel> {
  const AppScope({super.key, required AppModel model, required super.child}) : super(notifier: model);

  static AppModel of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
