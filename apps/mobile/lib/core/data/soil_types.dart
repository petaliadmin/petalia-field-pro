/// Catalogue des types de sol rencontrés dans le bassin arachidier et les
/// Niayes. Les étiquettes FR reprennent la terminologie ISRA/CNRA usuelle,
/// l'id est la valeur stockée en base (stable, indépendante de la langue).
///
/// Les recommandations agronomiques ajustent les doses d'eau et d'engrais
/// selon le type de sol — d'où la nécessité de conserver un référentiel
/// identifié plutôt qu'une chaîne libre.
import 'package:flutter/widgets.dart';
import '../../l10n/gen/app_localizations.dart';

class SoilType {
  final String id;

  const SoilType({
    required this.id,
  });

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (id) {
      'sandy' => l10n.soilSandyLabel,
      'sandy_loam' => l10n.soilSandyLoamLabel,
      'loam' => l10n.soilLoamLabel,
      'clay_loam' => l10n.soilClayLoamLabel,
      'clay' => l10n.soilClayLabel,
      'silt' => l10n.soilSiltLabel,
      _ => id,
    };
  }

  String description(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (id) {
      'sandy' => l10n.soilSandyDesc,
      'sandy_loam' => l10n.soilSandyLoamDesc,
      'loam' => l10n.soilLoamDesc,
      'clay_loam' => l10n.soilClayLoamDesc,
      'clay' => l10n.soilClayDesc,
      'silt' => l10n.soilSiltDesc,
      _ => '',
    };
  }
}

class SoilTypes {
  SoilTypes._();

  static const List<SoilType> all = [
    SoilType(id: 'sandy'),
    SoilType(id: 'sandy_loam'),
    SoilType(id: 'loam'),
    SoilType(id: 'clay_loam'),
    SoilType(id: 'clay'),
    SoilType(id: 'silt'),
  ];

  static SoilType? byId(String? id) {
    if (id == null) return null;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
