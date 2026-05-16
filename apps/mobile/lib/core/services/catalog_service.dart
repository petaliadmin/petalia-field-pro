import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../network/dio_client.dart';
import '../network/remote_sources/remote_sources_providers.dart';

class CatalogService {
  CatalogService(this._dio);
  final DioClient? _dio;

  Future<void> hydrate() async {
    final box = Hive.box(AppConstants.boxAgroRulesCache);
    final hasRules = box.containsKey('agro_rules');
    final hasSymptoms = box.containsKey('symptoms');

    if (AppConstants.remoteApiEnabled && _dio != null) {
      try {
        final resp = await _dio!.instance.get<Map<String, dynamic>>('/system/catalogs');
        final data = resp.data;
        if (data != null && data['upToDate'] != true) {
          if (data['rules'] != null) {
            await box.put('agro_rules', jsonEncode(data['rules']));
          }
          if (data['symptoms'] != null) {
            await box.put('symptoms', jsonEncode(data['symptoms']));
          }
          if (data['crops'] != null) {
            await box.put('crops', jsonEncode(data['crops']));
          }
          return;
        }
      } catch (_) {
        // En cas d'échec réseau (mode hors-ligne ou erreur serveur), on continue vers le fallback seed
      }
    }

    // Fallback Seed local si le cache est vide
    if (!hasRules) {
      try {
        final rawRules = await rootBundle.loadString('assets/agro_rules/agro_rules.json');
        await box.put('agro_rules', rawRules);
      } catch (_) {}
    }

    if (!hasSymptoms) {
      try {
        final rawSymptoms = await rootBundle.loadString('assets/data/symptoms.json');
        await box.put('symptoms', rawSymptoms);
      } catch (_) {}
    }
  }
}

final catalogServiceProvider = Provider<CatalogService>((ref) {
  final dio = ref.watch(remoteDioProvider);
  return CatalogService(dio);
});
