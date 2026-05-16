import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One symptom entry from `assets/data/symptoms.json`, resolved for a locale.
@immutable
class SymptomEntry {
  const SymptomEntry({
    required this.id,
    required this.icon,
    required this.label,
  });

  final String id;
  final IconData icon;
  final String label;
}

/// Loads and caches the localized symptoms catalog from JSON.
///
/// Falls back to French if a locale is missing. Icon names are mapped to
/// Material icons (subset used by the catalog).
class SymptomsCatalogService {
  SymptomsCatalogService._();

  static Map<String, dynamic>? _raw;

  static Future<List<SymptomEntry>> load(Locale locale) async {
    _raw ??= jsonDecode(
      await rootBundle.loadString('assets/data/symptoms.json'),
    ) as Map<String, dynamic>;

    final symptoms = (_raw!['symptoms'] as List).cast<Map<String, dynamic>>();
    final lang = locale.languageCode;

    return symptoms.map((s) {
      final labels = (s['labels'] as Map).cast<String, dynamic>();
      final label = (labels[lang] ?? labels['fr']) as String;
      return SymptomEntry(
        id: s['id'] as String,
        icon: _iconFor(s['icon'] as String),
        label: label,
      );
    }).toList(growable: false);
  }

  /// Map of [SymptomEntry.id] → icon, used when only the id is known
  /// (e.g. from stored observations, recommendations).
  static IconData iconForId(String id) {
    final raw = _raw?['symptoms'] as List?;
    if (raw == null) return Icons.help_outline_rounded;
    final entry = raw.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['id'] == id,
          orElse: () => const {'icon': 'help_outline_rounded'},
        );
    return _iconFor(entry['icon'] as String);
  }

  static String getLabelForId(String id, Locale locale) {
    final raw = _raw?['symptoms'] as List?;
    if (raw == null) return id;
    final entry = raw.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['id'] == id,
          orElse: () => const {},
        );
    if (entry.isEmpty) return id;
    final labels = (entry['labels'] as Map).cast<String, dynamic>();
    return (labels[locale.languageCode] ?? labels['fr']) as String;
  }

  static IconData _iconFor(String name) {
    return _iconMap[name] ?? Icons.help_outline_rounded;
  }

  // Subset registered for the catalog. Add here when adding new icons in JSON.
  static const Map<String, IconData> _iconMap = {
    'eco_rounded': Icons.eco_rounded,
    'bug_report_rounded': Icons.bug_report_rounded,
    'wb_sunny_rounded': Icons.wb_sunny_rounded,
    'grass_rounded': Icons.grass_rounded,
    'blur_on_rounded': Icons.blur_on_rounded,
    'circle_rounded': Icons.circle_rounded,
    'circle_outlined': Icons.circle_outlined,
    'colorize_rounded': Icons.colorize_rounded,
    'palette_rounded': Icons.palette_rounded,
    'height_rounded': Icons.height_rounded,
    'water_drop_outlined': Icons.water_drop_outlined,
    'bubble_chart_rounded': Icons.bubble_chart_rounded,
    'water_rounded': Icons.water_rounded,
    'warning_rounded': Icons.warning_rounded,
    'sell_rounded': Icons.sell_rounded,
    'sick_rounded': Icons.sick_rounded,
    'help_outline_rounded': Icons.help_outline_rounded,
  };
}

/// Riverpod provider — autoloads the catalog for the current MaterialApp locale.
final symptomsCatalogProvider =
    FutureProvider.family<List<SymptomEntry>, Locale>((ref, locale) {
  return SymptomsCatalogService.load(locale);
});
