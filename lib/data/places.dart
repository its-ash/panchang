import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../engine/engine.dart';

/// The offline list of cities in `assets/geo/cities.json`:
/// `[name, region, latitude, longitude, standard UTC offset in minutes]`.
class Places {
  Places._(this.all);

  final List<Place> all;

  static Places? _cache;

  static Future<Places> load([AssetBundle? bundle]) async {
    final cached = _cache;
    if (cached != null && bundle == null) return cached;
    final raw = jsonDecode(await (bundle ?? rootBundle).loadString('assets/geo/cities.json')) as Map;
    final list = <Place>[
      for (final c in raw['cities'] as List)
        Place(
          name: c[0] as String,
          region: c[1] as String,
          latitude: (c[2] as num).toDouble(),
          longitude: (c[3] as num).toDouble(),
          standardOffsetMinutes: (c[4] as num).toInt(),
        ),
    ];
    return _cache = Places._(list);
  }

  /// Cities whose name (or a word of it) starts with [query] first, then
  /// those that contain it in the name or region.
  List<Place> search(String query, {int limit = 40}) {
    final q = _fold(query.trim());
    if (q.isEmpty) return all.take(limit).toList();
    final starts = <Place>[], contains = <Place>[];
    for (final p in all) {
      final n = _fold(p.name);
      if (n.startsWith(q) || n.split(RegExp(r'[\s(\-]+')).any((w) => w.startsWith(q))) {
        starts.add(p);
      } else if (n.contains(q) || _fold(p.region).contains(q)) {
        contains.add(p);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  /// The listed city closest to a coordinate.
  Place nearest(double latitude, double longitude) {
    Place? best;
    var bestKm = double.infinity;
    for (final p in all) {
      final km = distanceKm(latitude, longitude, p.latitude, p.longitude);
      if (km < bestKm) {
        bestKm = km;
        best = p;
      }
    }
    return best!;
  }

  /// Great-circle distance in kilometres (haversine).
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0, rad = math.pi / 180;
    final dLat = (lat2 - lat1) * rad, dLon = (lon2 - lon1) * rad;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * rad) * math.cos(lat2 * rad) * math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll('ā', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ã', 'a')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ı', 'i');
}
