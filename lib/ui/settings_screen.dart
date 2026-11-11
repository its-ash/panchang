import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import 'location_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    return UiScaffold(
      appBar: UiAppBar(title: m.t('Settings', 'सेटिंग')),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSection(
            title: m.t('Language', 'भाषा'),
            child: UiSegmentedControl<bool>(
              const [UiSegment(false, label: 'English'), UiSegment(true, label: 'हिन्दी')],
              value: m.hindi,
              expand: true,
              onChanged: (v) => m.hindi = v,
            ),
          ),
          const UiGap(UiSpace.lg),
          UiSection(
            title: m.t('Month system', 'मास पद्धति'),
            child: UiSegmentedControl<bool>(
              [
                UiSegment(false, label: m.t('Amanta', 'अमांत')),
                UiSegment(true, label: m.t('Purnimanta', 'पूर्णिमांत')),
              ],
              value: m.purnimanta,
              expand: true,
              onChanged: (v) => m.purnimanta = v,
            ),
          ),
          const UiGap(UiSpace.xs),
          Text(
            m.t(
              'Amanta months end on the new moon (South and West India). Purnimanta months end on the full moon (North India).',
              'अमांत मास अमावस्या को समाप्त होते हैं (दक्षिण और पश्चिम भारत)। पूर्णिमांत मास पूर्णिमा को समाप्त होते हैं (उत्तर भारत)।',
            ),
            style: context.text.bodySmall,
          ),
          const UiGap(UiSpace.lg),
          UiListGroup(
            header: m.t('Location', 'स्थान'),
            footer: m.t('Sunrise, tithi times and muhurat are worked out for this city.',
                'सूर्योदय, तिथि के समय और मुहूर्त इसी शहर के लिए निकाले जाते हैं।'),
            children: [
              UiListTile(
                m.place.name,
                subtitle: m.place.region,
                icon: Icons.place_rounded,
                chevron: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LocationScreen())),
              ),
            ],
          ),
          const UiGap(UiSpace.lg),
          UiUpdateSection(storeId: 'panchang', header: m.t('Updates', 'अपडेट')),
          const UiGap(UiSpace.lg),
          UiDeveloperSection(header: m.t('Developer', 'डेवलपर')),
        ],
      ),
    );
  }
}
