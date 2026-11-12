import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:panchang/app/app_model.dart';
import 'package:panchang/app/widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('widget payload has one entry per day with five rows', () async {
    SharedPreferences.setMockInitialValues({});
    final m = await AppModel.load();
    final data = jsonDecode(WidgetSync.build(m, from: DateTime(2026, 2, 15), count: 3)) as Map<String, dynamic>;
    final days = data['days'] as Map<String, dynamic>;
    expect(days.keys, ['2026-02-15', '2026-02-16', '2026-02-17']);
    expect((days['2026-02-15']['rows'] as List).length, 5);
    expect(data['place'], isNotEmpty);
  });
}
