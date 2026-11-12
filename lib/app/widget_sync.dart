import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/names.dart';
import '../engine/engine.dart';
import '../ui/format.dart';
import 'app_model.dart';

/// Pushes the next [days] days of panchang to the Android home-screen widget.
///
/// The engine is Dart only, so the widget (Kotlin) cannot compute anything: it
/// reads one JSON string from SharedPreferences and picks today's entry by the
/// local date. We rewrite that string whenever the place, language or month
/// system changes, and at app start.
class WidgetSync {
  WidgetSync(this._model) {
    _sig = _signature();
    _model.addListener(_onChange);
  }

  static const days = 30;
  static const _channel = MethodChannel('com.itsash.panchang/widget');

  final AppModel _model;
  late String _sig;

  String _signature() => '${_model.place.key}|${_model.place.label}|${_model.hindi}|${_model.purnimanta}';

  void _onChange() {
    final s = _signature();
    if (s == _sig) return; // only the selected date changed
    _sig = s;
    push();
  }

  void dispose() => _model.removeListener(_onChange);

  /// Compact JSON: `{"place": "...", "days": {"2026-02-15": {"t": "Sunday, ...", "rows": [[label, value], ...]}}}`.
  static String build(AppModel m, {DateTime? from, int count = days}) {
    final now = from ?? DateTime.now();
    final out = <String, Object>{};
    for (var i = 0; i < count; i++) {
      final d = DateTime.utc(now.year, now.month, now.day + i);
      final p = Panchang.compute(m.place, d.year, d.month, d.day);
      final mu = Muhurat.compute(sunrise: p.sunrise, sunset: p.sunset, nextSunrise: p.nextSunrise, weekday: p.weekday);
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      out[key] = {
        't': m.longDate(d),
        'rows': [
          [m.t('Tithi', 'तिथि'), m.tithiWithPaksha(p.tithi.index)],
          [m.t('Nakshatra', 'नक्षत्र'), m.bi(Names.nakshatra[p.nakshatra.index])],
          [m.t('Sunrise', 'सूर्योदय'), m.clock(p.sunrise)],
          [m.t('Sunset', 'सूर्यास्त'), m.clock(p.sunset)],
          [m.t('Rahu Kaal', 'राहु काल'), m.range(mu.rahuKaal, day: d)],
        ],
      };
    }
    return jsonEncode({
      'place': m.place.label,
      'msg': m.t('Open Panchang to update', 'अपडेट के लिए पंचांग खोलें'),
      'days': out,
    });
  }

  /// Computes and sends the data, then asks the widget to redraw. Never throws
  /// (no native side on tests or other platforms).
  Future<void> push() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      // Let the first frame paint before the ~30 day computation.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _channel.invokeMethod<void>('update', build(_model));
    } on PlatformException catch (e) {
      debugPrint('widget sync failed: $e');
    } on MissingPluginException {
      // Not running on Android.
    }
  }
}
