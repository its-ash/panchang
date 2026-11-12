import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import 'app/app_model.dart';
import 'app/widget_sync.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = await AppModel.load();
  WidgetSync(model).push();
  runApp(PanchangApp(model: model));
}

class PanchangApp extends StatelessWidget {
  const PanchangApp({super.key, required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      model: model,
      child: UiApp(
        title: 'Panchang',
        accent: const Color(0xFFE8590C), // saffron
        home: const HomeScreen(),
      ),
    );
  }
}
