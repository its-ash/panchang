import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../data/names.dart';
import '../engine/engine.dart';
import 'format.dart';
import 'location_screen.dart';

/// The day's panchang: tithi, nakshatra, yoga, karana, sun and moon times,
/// month and year.
class PanchangPage extends StatelessWidget {
  const PanchangPage({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final p = m.panchang;
    final day = m.date;
    final pad = UiContent.pagePadding(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, UiSpace.sm, pad, UiSpace.xxl),
      children: [
        const DateBar(),
        const UiGap(UiSpace.md),
        _Hero(p: p),
        const UiGap(UiSpace.lg),
        UiListGroup(
          header: m.t('Five limbs of the day', 'आज के पंचांग के पाँच अंग'),
          footer: m.t('Times are for the day from sunrise to the next sunrise.',
              'समय सूर्योदय से अगले सूर्योदय तक के दिन के लिए हैं।'),
          children: [
            for (final s in p.tithis)
              UiListTile(
                m.t('Tithi', 'तिथि'),
                icon: Icons.brightness_2_rounded,
                subtitle: '${m.tithiWithPaksha(s.index)}${_ends(m, s, p, day)}',
                maxSubtitleLines: 2,
              ),
            for (final s in p.nakshatras)
              UiListTile(
                m.t('Nakshatra', 'नक्षत्र'),
                icon: Icons.auto_awesome_rounded,
                subtitle: '${m.bi(Names.nakshatra[s.index])}${_ends(m, s, p, day)}',
              ),
            for (final s in p.yogas)
              UiListTile(
                m.t('Yoga', 'योग'),
                icon: Icons.self_improvement_rounded,
                subtitle: '${m.bi(Names.yoga[s.index])}${_ends(m, s, p, day)}',
              ),
            for (final s in p.karanas)
              UiListTile(
                m.t('Karana', 'करण'),
                icon: Icons.timelapse_rounded,
                subtitle: '${m.bi(Names.karana(s.index))}${_ends(m, s, p, day)}',
              ),
            UiListTile(
              m.t('Vaar (weekday)', 'वार'),
              icon: Icons.today_rounded,
              subtitle: m.bi(Names.vaar[p.weekday]!),
            ),
          ],
        ),
        const UiGap(UiSpace.lg),
        UiListGroup(
          header: m.t('Sun and Moon', 'सूर्य और चंद्रमा'),
          children: [
            UiListTile(m.t('Sunrise', 'सूर्योदय'),
                icon: Icons.wb_sunny_rounded, iconStatus: UiStatus.warning, value: m.clock(p.sunrise)),
            UiListTile(m.t('Sunset', 'सूर्यास्त'),
                icon: Icons.nights_stay_rounded, iconStatus: UiStatus.danger, value: m.clock(p.sunset)),
            UiListTile(m.t('Moonrise', 'चंद्रोदय'),
                icon: Icons.nightlight_round, iconStatus: UiStatus.info,
                value: p.moonrise == null ? m.t('none', 'नहीं') : m.clock(p.moonrise!, day: day)),
            UiListTile(m.t('Moonset', 'चंद्रास्त'),
                icon: Icons.bedtime_outlined, iconStatus: UiStatus.info,
                value: p.moonset == null ? m.t('none', 'नहीं') : m.clock(p.moonset!, day: day)),
            for (final s in p.moonRashis)
              UiListTile(
                m.t('Moon sign (Rashi)', 'चंद्र राशि'),
                icon: Icons.circle_outlined,
                subtitle: '${m.bi(Names.rashi[s.index])}${s.end.isBefore(p.nextSunrise) ? _ends(m, s, p, day) : ''}',
              ),
            for (final s in p.sunRashis)
              UiListTile(
                m.t('Sun sign', 'सूर्य राशि'),
                icon: Icons.light_mode_outlined,
                subtitle: '${m.bi(Names.rashi[s.index])}${s.end.isBefore(p.nextSunrise) ? _ends(m, s, p, day) : ''}',
              ),
          ],
        ),
        const UiGap(UiSpace.lg),
        UiListGroup(
          header: m.t('Calendar', 'पंचांग वर्ष'),
          children: [
            UiListTile(
              m.t('Hindu month', 'हिंदू मास'),
              icon: Icons.calendar_month_rounded,
              subtitle:
                  '${m.monthLabel(p)} (${m.purnimanta ? m.t('Purnimanta', 'पूर्णिमांत') : m.t('Amanta', 'अमांत')}) · ${m.pakshaName(p.tithi.index)}',
            ),
            UiListTile(m.t('Vikram Samvat', 'विक्रम संवत'), icon: Icons.history_edu_rounded, value: '${p.vikramSamvat}'),
            UiListTile(m.t('Shaka Samvat', 'शक संवत'), icon: Icons.history_rounded, value: '${p.shakaSamvat}'),
            UiListTile(m.t('Ritu (season)', 'ऋतु'), icon: Icons.thermostat_rounded, subtitle: m.bi(Names.ritu[p.ritu])),
            UiListTile(
              m.t('Ayana', 'अयन'),
              icon: Icons.swap_vert_rounded,
              subtitle: m.bi(p.uttarayana ? Names.uttarayana : Names.dakshinayana),
            ),
          ],
        ),
      ],
    );
  }

  /// " · until 5:04 PM" for a segment, or " · full day" when it spans the day.
  static String _ends(AppModel m, Segment s, Panchang p, DateTime day) {
    if (!s.end.isBefore(p.nextSunrise)) return ' · ${m.t('till next sunrise', 'अगले सूर्योदय तक')}';
    return ' · ${m.until(s.end, day: day)}';
  }
}

/// Previous and next day, the date and the place.
class DateBar extends StatelessWidget {
  const DateBar({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final c = context.colors;
    return Column(
      children: [
        Row(
          children: [
            UiIconButton(Icons.chevron_left_rounded, tooltip: m.t('Previous day', 'पिछला दिन'), onPressed: () => m.shiftDays(-1)),
            Expanded(
              child: InkWell(
                borderRadius: UiRadius.all(UiRadius.md),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: m.date,
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) m.date = picked;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: UiSpace.xs),
                  child: Column(
                    children: [
                      Text(m.longDate(m.date), style: context.text.titleMedium, textAlign: TextAlign.center),
                      const UiGap(UiSpace.xxs),
                      Text(m.t('Tap to pick a date', 'तारीख़ चुनने के लिए दबाएँ'), style: context.text.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
            UiIconButton(Icons.chevron_right_rounded, tooltip: m.t('Next day', 'अगला दिन'), onPressed: () => m.shiftDays(1)),
          ],
        ),
        const UiGap(UiSpace.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              borderRadius: UiRadius.all(UiRadius.full),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LocationScreen())),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: UiSpace.md, vertical: UiSpace.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_rounded, size: 16, color: c.accent),
                    const UiGap(UiSpace.xs),
                    Flexible(child: Text(m.place.label, style: context.text.labelLarge?.copyWith(color: c.accent), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
            if (!m.isToday) UiButton(m.t('Today', 'आज'), size: UiSize.sm, variant: UiButtonVariant.soft, onPressed: m.goToday),
          ],
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.p});

  final Panchang p;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final c = context.colors;
    final tithi = p.tithi;
    final specials = <(String, UiStatus)>[
      if (tithi.index == 14) (m.t('Purnima', 'पूर्णिमा'), UiStatus.warning),
      if (tithi.index == 29) (m.t('Amavasya', 'अमावस्या'), UiStatus.info),
      if (tithi.index == 10 || tithi.index == 25) (m.t('Ekadashi', 'एकादशी'), UiStatus.success),
    ];
    return UiCard(
      variant: UiCardVariant.filled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.pakshaName(tithi.index), style: context.text.labelMedium?.copyWith(color: c.textMuted)),
          const UiGap(UiSpace.xs),
          Text(m.tithiName(tithi.index), style: context.text.headlineLarge),
          const UiGap(UiSpace.xs),
          Text(
            tithi.end.isBefore(p.nextSunrise)
                ? m.until(tithi.end, day: m.date)
                : m.t('till next sunrise', 'अगले सूर्योदय तक'),
            style: context.text.bodyMedium?.copyWith(color: c.textMuted),
          ),
          const UiGap(UiSpace.md),
          Wrap(
            spacing: UiSpace.sm,
            runSpacing: UiSpace.sm,
            children: [
              UiStatusPill(m.monthLabel(p), status: UiStatus.accent),
              UiStatusPill(m.bi(Names.nakshatra[p.nakshatra.index]), status: UiStatus.neutral),
              for (final s in specials) UiStatusPill(s.$1, status: s.$2),
            ],
          ),
        ],
      ),
    );
  }
}
