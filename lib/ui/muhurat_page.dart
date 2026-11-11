import 'dart:async';

import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../data/names.dart';
import '../engine/engine.dart';
import 'format.dart';
import 'panchang_page.dart';

/// Auspicious and inauspicious timings and the choghadiya of the day. The
/// choghadiya that is running now is highlighted.
class MuhuratPage extends StatefulWidget {
  const MuhuratPage({super.key});

  @override
  State<MuhuratPage> createState() => _MuhuratPageState();
}

class _MuhuratPageState extends State<MuhuratPage> {
  late DateTime _now = DateTime.now().toUtc();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() => _now = DateTime.now().toUtc()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final p = m.panchang;
    final day = m.date;
    final mu = Muhurat.compute(sunrise: p.sunrise, sunset: p.sunset, nextSunrise: p.nextSunrise, weekday: p.weekday);
    final pad = UiContent.pagePadding(context);

    UiListTile row(String title, TimeWindow w, IconData icon, UiStatus status, {String? subtitle}) {
      final now = w.contains(_now);
      return UiListTile(
        title,
        icon: icon,
        iconStatus: status,
        subtitle: subtitle ?? m.range(w, day: day),
        selected: now,
        trailing: now ? UiStatusPill(m.t('Now', 'अभी'), status: status) : null,
      );
    }

    Widget choghadiya(bool isDay) {
      final items = mu.choghadiya.where((c) => c.isDay == isDay);
      return UiListGroup(
        header: isDay ? m.t('Choghadiya: day', 'चौघड़िया: दिन') : m.t('Choghadiya: night', 'चौघड़िया: रात'),
        children: [
          for (final c in items)
            UiListTile(
              m.bi(Names.choghadiya[c.kind]),
              icon: c.isAuspicious ? Icons.check_circle_rounded : (c.kind == 1 ? Icons.remove_circle_rounded : Icons.cancel_rounded),
              iconStatus: c.isAuspicious ? UiStatus.success : (c.kind == 1 ? UiStatus.warning : UiStatus.danger),
              subtitle: m.range(c.window, day: day),
              selected: c.window.contains(_now),
              trailing: c.window.contains(_now) ? UiStatusPill(m.t('Now', 'अभी'), status: UiStatus.accent) : null,
            ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, UiSpace.sm, pad, UiSpace.xxl),
      children: [
        const DateBar(),
        const UiGap(UiSpace.lg),
        UiListGroup(
          header: m.t('Auspicious', 'शुभ समय'),
          children: [
            if (mu.abhijit != null)
              row(m.t('Abhijit Muhurat', 'अभिजित मुहूर्त'), mu.abhijit!, Icons.star_rounded, UiStatus.success)
            else
              UiListTile(m.t('Abhijit Muhurat', 'अभिजित मुहूर्त'),
                  icon: Icons.star_outline_rounded, subtitle: m.t('Not observed on Wednesday', 'बुधवार को नहीं माना जाता')),
            row(m.t('Brahma Muhurat', 'ब्रह्म मुहूर्त'), mu.brahma, Icons.self_improvement_rounded, UiStatus.success),
          ],
        ),
        const UiGap(UiSpace.lg),
        UiListGroup(
          header: m.t('Inauspicious', 'अशुभ समय'),
          footer: m.t('Avoid starting new and important work in these periods.',
              'इन समयों में नया और महत्वपूर्ण कार्य आरंभ करने से बचें।'),
          children: [
            row(m.t('Rahu Kaal', 'राहु काल'), mu.rahuKaal, Icons.warning_amber_rounded, UiStatus.danger),
            row(m.t('Yamaganda', 'यमगण्ड'), mu.yamaganda, Icons.warning_amber_rounded, UiStatus.warning),
            row(m.t('Gulika Kaal', 'गुलिक काल'), mu.gulikaKaal, Icons.warning_amber_rounded, UiStatus.warning),
            for (final w in mu.durMuhurat) row(m.t('Dur Muhurat', 'दुर्मुहूर्त'), w, Icons.block_rounded, UiStatus.danger),
          ],
        ),
        const UiGap(UiSpace.lg),
        choghadiya(true),
        const UiGap(UiSpace.lg),
        choghadiya(false),
      ],
    );
  }
}
