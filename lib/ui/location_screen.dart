import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../data/places.dart';
import '../engine/engine.dart';

/// Pick a city from the offline list, or let GPS choose the nearest one.
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late final Future<Places> _places = Places.load();
  String _query = '';
  bool _locating = false;

  Future<void> _useGps(Places places) async {
    final m = AppScope.of(context);
    setState(() => _locating = true);
    String? error;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        error = m.t('Turn on location services and try again.', 'लोकेशन सेवा चालू करके फिर कोशिश करें।');
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          error = m.t('Location permission was not given.', 'लोकेशन की अनुमति नहीं मिली।');
        } else {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 20)),
          );
          final city = places.nearest(pos.latitude, pos.longitude);
          m.place = city;
          if (!mounted) return;
          context.showToast(m.t('Location set to ${city.name}', 'स्थान: ${city.name}'), status: UiStatus.success);
          Navigator.of(context).pop();
          return;
        }
      }
    } catch (_) {
      error = m.t('Could not get your location.', 'आपका स्थान नहीं मिल सका।');
    }
    if (!mounted) return;
    setState(() => _locating = false);
    context.showToast(error, status: UiStatus.warning);
  }

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    return UiScaffold(
      appBar: UiAppBar(title: m.t('Location', 'स्थान')),
      body: FutureBuilder<Places>(
        future: _places,
        builder: (context, snap) {
          final places = snap.data;
          if (places == null) return const Center(child: UiSpinner());
          final results = places.search(_query);
          return Column(
            children: [
              UiSearchField(
                hint: m.t('Search city', 'शहर खोजें'),
                onChanged: (v) => setState(() => _query = v),
              ),
              const UiGap(UiSpace.md),
              UiButton(
                m.t('Use my location', 'मेरा स्थान उपयोग करें'),
                icon: Icons.my_location_rounded,
                variant: UiButtonVariant.soft,
                expand: true,
                loading: _locating,
                onPressed: () => _useGps(places),
              ),
              const UiGap(UiSpace.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  m.t('GPS is used once to pick the nearest city. Nothing is stored or sent.',
                      'GPS केवल एक बार निकटतम शहर चुनने के लिए उपयोग होता है। कुछ भी सहेजा या भेजा नहीं जाता।'),
                  style: context.text.bodySmall,
                ),
              ),
              const UiGap(UiSpace.md),
              Expanded(
                child: results.isEmpty
                    ? UiEmptyState(
                        title: m.t('No city found', 'कोई शहर नहीं मिला'),
                        message: m.t('Try another spelling, or the nearest big city.', 'दूसरी वर्तनी या पास का बड़ा शहर आज़माएँ।'),
                        icon: Icons.search_off_rounded,
                      )
                    : ListView(
                        children: [
                          UiListGroup(
                            children: [
                              for (final Place p in results)
                                UiListTile(
                                  p.name,
                                  subtitle: p.region,
                                  icon: Icons.location_city_rounded,
                                  selected: p == m.place,
                                  trailing: p == m.place ? const Icon(Icons.check_rounded) : null,
                                  onTap: () {
                                    m.place = p;
                                    Navigator.of(context).pop();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
