import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import 'calendar_page.dart';
import 'muhurat_page.dart';
import 'panchang_page.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    return UiShell(
      appBar: UiAppBar(
        title: m.t('Panchang', 'पंचांग'),
        actions: [
          UiIconButton(
            Icons.settings_rounded,
            tooltip: m.t('Settings', 'सेटिंग'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      items: [
        UiNavItem(Icons.today_outlined, m.t('Today', 'आज'), selectedIcon: Icons.today_rounded),
        UiNavItem(Icons.calendar_month_outlined, m.t('Calendar', 'कैलेंडर'), selectedIcon: Icons.calendar_month_rounded),
        UiNavItem(Icons.schedule_outlined, m.t('Muhurat', 'मुहूर्त'), selectedIcon: Icons.schedule_rounded),
      ],
      index: _tab,
      onChanged: (i) => setState(() => _tab = i),
      pages: [
        const PanchangPage(),
        CalendarPage(onOpenDay: () => setState(() => _tab = 0)),
        const MuhuratPage(),
      ],
    );
  }
}
