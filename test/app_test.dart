import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panchang/app/app_model.dart';
import 'package:panchang/data/places.dart';
import 'package:panchang/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  UiTypography.useGoogleFonts = false;

  test('city list loads and finds the nearest city', () async {
    final places = await Places.load();
    expect(places.all.length, greaterThan(300));
    expect(places.nearest(28.5, 77.4).name, 'Noida');
    expect(places.nearest(51.5, -0.1).name, 'London');
    expect(places.search('delh').first.name, anyOf('New Delhi', 'Delhi'));
    expect(places.search('sao paulo').first.name, 'São Paulo'); // accents are ignored
    expect(places.search('Mumbai').first.name, 'Mumbai');
  });

  test('settings are remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final m = await AppModel.load();
    expect(m.hindi, isFalse);
    expect(m.place.name, 'New Delhi');
    m
      ..hindi = true
      ..purnimanta = true
      ..place = (await Places.load()).search('Pune').first;
    final again = await AppModel.load();
    expect(again.hindi, isTrue);
    expect(again.purnimanta, isTrue);
    expect(again.place.name, 'Pune');
  });

  testWidgets('home shows today and switches language', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final model = await AppModel.load();
    tester.view
      ..physicalSize = const Size(800, 3200) // tall, so every list row is built
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PanchangApp(model: model));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Panchang'), findsWidgets);
    expect(find.text('Sunrise'), findsOneWidget);
    model.hindi = true;
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('सूर्योदय'), findsOneWidget);

    await tester.tap(find.text('कैलेंडर'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('पूर्णिमा'), findsWidgets);
    await tester.tap(find.text('मुहूर्त'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('राहु काल'), findsOneWidget);
  });
}
