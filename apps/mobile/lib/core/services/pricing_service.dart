import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

/// Service gérant les prix dynamiques des intrants sur le marché sénégalais.
/// Permet de surcharger les prix statiques du JSON par des données temps réel.
class PricingService {
  PricingService();

  /// Mock de prix du marché (SIM - Système d'Information sur le Marché).
  /// À terme, ces données viennent d'une API via [SyncService].
  static const Map<String, int> _defaultMarketPrices = {
    'urea': 18500,
    'npk': 19000,
    'chlorpyrifos': 8500,
    'mancozeb': 7000,
    'glyphosate': 6500,
  };

  /// Récupère le prix actuel pour un produit, avec fallback sur la valeur statique.
  int getEffectivePrice(String productKey, int staticPrice) {
    final box = Hive.box(AppConstants.boxSettings);
    final remotePrices = box.get('market_prices', defaultValue: <String, int>{}) as Map;
    
    final key = productKey.toLowerCase().trim();
    return (remotePrices[key] as int?) ?? _defaultMarketPrices[key] ?? staticPrice;
  }
}

final pricingServiceProvider = Provider((ref) => PricingService());
