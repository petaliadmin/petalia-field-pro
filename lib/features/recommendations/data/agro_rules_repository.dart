import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/crops_catalog.dart';
import '../../../core/network/remote_sources/remote_sources_providers.dart';
import '../domain/agro_rule.dart';

/// Provides the full list of agro rules (loaded once, cached in memory).
final agroRulesProvider = FutureProvider<List<AgroRule>>((ref) {
  final source = ref.watch(agroRulesRemoteSourceProvider);
  return source.fetchAll();
});

/// Determines the current agricultural season based on month.
/// Hivernage (rainy): June-October — Contre-saison (dry/irrigated): Nov-May.
String currentSeason([DateTime? ref]) {
  final month = (ref ?? DateTime.now()).month;
  return (month >= 6 && month <= 10) ? 'hivernage' : 'contreSaison';
}

/// Resolves the crop ID from either a crop label (FR) or an already-valid
/// crop ID. Returns lowercase ASCII crop ID or the input unchanged.
String resolveCropId(String cropNameOrId) {
  final byLabel = CropsCatalog.byLabelFr(cropNameOrId);
  if (byLabel != null) return byLabel.id;
  final byId = CropsCatalog.byId(cropNameOrId);
  if (byId != null) return byId.id;
  return cropNameOrId.toLowerCase();
}

/// Filters and ranks agro rules for a given observation context.
///
/// Returns matched rules sorted by specificity score (highest first).
List<AgroRule> matchRules({
  required List<AgroRule> allRules,
  required String crop,
  required String stage,
  required List<String> symptoms,
  required double severity,
  String? region,
  String? season,
}) {
  final cropId = resolveCropId(crop);
  final effectiveSeason = season ?? currentSeason();
  final effectiveRegion = region ?? '*';

  final matched = <AgroRule>[];
  for (final rule in allRules) {
    for (final symptom in symptoms) {
      if (rule.matches(
        crop: cropId,
        stage: stage,
        symptom: symptom,
        season: effectiveSeason,
        region: effectiveRegion,
        severity: severity,
      )) {
        matched.add(rule);
        break; // one match per rule is enough
      }
    }
  }

  // Sort by specificity: most specific rules first.
  matched.sort((a, b) => b.specificityScore().compareTo(a.specificityScore()));
  return matched;
}
