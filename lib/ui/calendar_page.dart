import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../data/names.dart';
import '../engine/engine.dart';
import 'format.dart';

/// First month of the swipeable calendar: January 1950.
const _firstYear = 1950;
const _monthCount = (2100 - _firstYear + 1) * 12;

int _pageOf(int year, int month) => (year - _firstYear) * 12 + month - 1;

/// A month grid with the tithi at sunrise for every day. Swipe sideways to
/// change month; tap a day to open it.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.onOpenDay});

  /// Called after a day has been selected.
  final VoidCallback onOpenDay;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _DayInfo {
  const _DayInfo(this.date, this.tithi);

  final DateTime date;
  final int tithi;
}

class _CalendarPageState extends State<CalendarPage> {
  late final PageController _controller;
  late int _page;
  int? _modelPage;
  final _months = <String, List<_DayInfo>>{};

  @override
  void initState() {
    super.initState();
    final d = DateTime.now();
    _page = _pageOf(d.year, d.month);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_DayInfo> _month(AppModel m, int page) {
    final year = _firstYear + page ~/ 12, month = page % 12 + 1;
    return _months.putIfAbsent('${m.place.key}|$page', () {
      if (_months.length > 24) _months.clear();
      final days = DateTime.utc(year, month + 1, 0).day;
      return [
        for (var d = 1; d <= days; d++) _DayInfo(DateTime.utc(year, month, d), Panchang.quick(m.place, year, month, d).tithi.index),
      ];
    });
  }

  void _go(int delta) {
    final target = (_page + delta).clamp(0, _monthCount - 1);
    _controller.animateToPage(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    // Follow the selected date when it moves to another month elsewhere.
    final target = _pageOf(m.date.year, m.date.month);
    if (target != _modelPage) {
      _modelPage = target;
      if (target != _page) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) _controller.jumpToPage(target);
        });
      }
    }
    final year = _firstYear + _page ~/ 12, month = _page % 12 + 1;
    final pad = UiContent.pagePadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, UiSpace.sm, pad, UiSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              UiIconButton(Icons.chevron_left_rounded, tooltip: m.t('Previous month', 'पिछला महीना'), onPressed: () => _go(-1)),
              Expanded(
                child: Column(
                  children: [
                    Text(m.monthYear(year, month), style: context.text.titleLarge),
                    Text(m.place.label, style: context.text.bodySmall, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              UiIconButton(Icons.chevron_right_rounded, tooltip: m.t('Next month', 'अगला महीना'), onPressed: () => _go(1)),
            ],
          ),
          const UiGap(UiSpace.sm),
          _WeekdayHeader(m: m),
          const UiGap(UiSpace.xs),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _monthCount,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, page) {
                if ((page - _page).abs() > 1) return const SizedBox.shrink();
                return _MonthGrid(
                  m: m,
                  days: _month(m, page),
                  onTap: (d) {
                    m.date = d;
                    widget.onOpenDay();
                  },
                );
              },
            ),
          ),
          const UiGap(UiSpace.sm),
          _Legend(m: m),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.m});

  final AppModel m;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final w in const [7, 1, 2, 3, 4, 5, 6])
          Expanded(
            child: Center(
              child: Text(m.bi(Names.vaarShort[w]!), style: context.text.labelMedium?.copyWith(color: context.colors.textMuted)),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.m, required this.days, required this.onTap});

  final AppModel m;
  final List<_DayInfo> days;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final lead = days.first.date.weekday % 7; // Sunday first
    final cells = <_DayInfo?>[...List.filled(lead, null), ...days];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final rows = cells.length ~/ 7;
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: cells[r * 7 + c] == null
                        ? const SizedBox.shrink()
                        : _DayCell(
                            m: m,
                            info: cells[r * 7 + c]!,
                            isToday: cells[r * 7 + c]!.date == today,
                            isSelected: cells[r * 7 + c]!.date == m.date,
                            onTap: onTap,
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.m, required this.info, required this.isToday, required this.isSelected, required this.onTap});

  final AppModel m;
  final _DayInfo info;
  final bool isToday, isSelected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = info.tithi;
    final purnima = t == 14, amavasya = t == 29, ekadashi = t == 10 || t == 25;
    final Color? marker = purnima
        ? c.warning
        : amavasya
            ? c.info
            : ekadashi
                ? c.success
                : null;
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: InkWell(
        borderRadius: UiRadius.all(UiRadius.sm),
        onTap: () => onTap(info.date),
        child: Ink(
          decoration: BoxDecoration(
            color: isToday ? c.accentSoft : marker?.withValues(alpha: 0.10),
            borderRadius: UiRadius.all(UiRadius.sm),
            border: isSelected ? Border.all(color: c.accent, width: 1.5) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${info.date.day}',
                style: context.text.titleSmall?.copyWith(color: isToday ? c.onAccentSoft : c.text),
              ),
              const UiGap(UiSpace.xxs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    m.tithiName(t),
                    maxLines: 1,
                    style: context.text.labelSmall?.copyWith(color: marker ?? c.textMuted, fontWeight: marker != null ? FontWeight.w700 : null),
                  ),
                ),
              ),
              const UiGap(UiSpace.xxs),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: marker,
                  shape: BoxShape.circle,
                  border: amavasya ? Border.all(color: c.info, width: 1.5) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.m});

  final AppModel m;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const UiGap(UiSpace.xs),
            Text(label, style: context.text.bodySmall),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: UiSpace.lg,
      runSpacing: UiSpace.xs,
      children: [
        item(c.warning, m.t('Purnima', 'पूर्णिमा')),
        item(c.info, m.t('Amavasya', 'अमावस्या')),
        item(c.success, m.t('Ekadashi', 'एकादशी')),
      ],
    );
  }
}
