import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../network/dio_client.dart';
import '../network/remote_sources/remote_sources_providers.dart';

class CatalogHydrationState {
  const CatalogHydrationState({
    this.progress = 0.0,
    this.statusText = '',
    this.isHydrating = false,
    this.isCompleted = false,
    this.hasError = false,
  });

  final double progress;
  final String statusText;
  final bool isHydrating;
  final bool isCompleted;
  final bool hasError;

  CatalogHydrationState copyWith({
    double? progress,
    String? statusText,
    bool? isHydrating,
    bool? isCompleted,
    bool? hasError,
  }) {
    return CatalogHydrationState(
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      isHydrating: isHydrating ?? this.isHydrating,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: hasError ?? this.hasError,
    );
  }
}

class CatalogService extends StateNotifier<CatalogHydrationState> {
  CatalogService(this._dio) : super(const CatalogHydrationState()) {
    final box = Hive.box(AppConstants.boxAgroRulesCache);
    if (box.containsKey('catalog_hydrated_v2')) {
      state = const CatalogHydrationState(progress: 1.0, isCompleted: true, statusText: 'Données hors-ligne à jour.');
    }
  }

  final DioClient? _dio;

  Future<void> hydrate({bool force = false}) async {
    final box = Hive.box(AppConstants.boxAgroRulesCache);
    if (!force && box.containsKey('catalog_hydrated_v2')) {
      state = const CatalogHydrationState(progress: 1.0, isCompleted: true, statusText: 'Données hors-ligne à jour.');
      return;
    }

    state = const CatalogHydrationState(isHydrating: true, progress: 0.1, statusText: 'Connexion au serveur de catalogues...');

    if (AppConstants.remoteApiEnabled && _dio != null) {
      try {
        final resp = await _dio!.instance.get<Map<String, dynamic>>('/system/catalogs');
        final data = resp.data;
        if (data != null && data['upToDate'] != true) {
          state = state.copyWith(progress: 0.3, statusText: 'Téléchargement des règles agronomiques...');
          if (data['rules'] != null) {
            await box.put('agro_rules', jsonEncode(data['rules']));
          }

          state = state.copyWith(progress: 0.5, statusText: 'Téléchargement des symptômes et cultures...');
          if (data['symptoms'] != null) {
            await box.put('symptoms', jsonEncode(data['symptoms']));
          }
          if (data['crops'] != null) {
            await box.put('crops', jsonEncode(data['crops']));
          }

          state = state.copyWith(progress: 0.7, statusText: 'Téléchargement des fournisseurs et matériels...');
          if (data['suppliers'] != null) {
            await box.put('suppliers', jsonEncode(data['suppliers']));
          }
          if (data['equipments'] != null) {
            await box.put('equipments', jsonEncode(data['equipments']));
          }

          state = state.copyWith(progress: 0.9, statusText: 'Téléchargement des institutions...');
          if (data['institutions'] != null) {
            await box.put('institutions', jsonEncode(data['institutions']));
          }

          await box.put('catalog_hydrated_v2', true);
          state = const CatalogHydrationState(progress: 1.0, isCompleted: true, statusText: 'Synchronisation hors-ligne terminée avec succès !');
          return;
        } else if (data != null && data['upToDate'] == true) {
          await box.put('catalog_hydrated_v2', true);
          state = const CatalogHydrationState(progress: 1.0, isCompleted: true, statusText: 'Données hors-ligne à jour.');
          return;
        }
      } catch (e) {
        state = state.copyWith(statusText: 'Mode hors-ligne actif. Chargement des données de secours...');
      }
    }

    // Fallback Seed local si le cache est vide ou échec réseau
    state = state.copyWith(progress: 0.4, statusText: 'Chargement des règles locales de secours...');
    if (!box.containsKey('agro_rules')) {
      try {
        final rawRules = await rootBundle.loadString('assets/agro_rules/agro_rules.json');
        await box.put('agro_rules', rawRules);
      } catch (_) {}
    }

    state = state.copyWith(progress: 0.8, statusText: 'Chargement des symptômes locaux...');
    if (!box.containsKey('symptoms')) {
      try {
        final rawSymptoms = await rootBundle.loadString('assets/data/symptoms.json');
        await box.put('symptoms', rawSymptoms);
      } catch (_) {}
    }

    await box.put('catalog_hydrated_v2', true);
    state = const CatalogHydrationState(progress: 1.0, isCompleted: true, statusText: 'Données de secours initialisées.');
  }

  Map<String, dynamic>? getCropsData() {
    final box = Hive.box(AppConstants.boxAgroRulesCache);
    final str = box.get('crops') as String?;
    if (str == null) return null;
    try { return jsonDecode(str) as Map<String, dynamic>; } catch (_) { return null; }
  }

  List<dynamic> getSuppliers() {
    final box = Hive.box(AppConstants.boxAgroRulesCache);
    final str = box.get('suppliers') as String?;
    if (str == null) return [];
    try { return jsonDecode(str) as List<dynamic>; } catch (_) { return []; }
  }

  List<dynamic> getEquipments() {
    final box = Hive.box(AppConstants.boxAgroRulesCache);
    final str = box.get('equipments') as String?;
    if (str == null) return [];
    try { return jsonDecode(str) as List<dynamic>; } catch (_) { return []; }
  }

  List<dynamic> getInstitutions() {
    final box = Hive.box(AppConstants.boxAgroRulesCache);
    final str = box.get('institutions') as String?;
    if (str == null) return [];
    try { return jsonDecode(str) as List<dynamic>; } catch (_) { return []; }
  }
}

final catalogServiceProvider = StateNotifierProvider<CatalogService, CatalogHydrationState>((ref) {
  final dio = ref.watch(remoteDioProvider);
  return CatalogService(dio);
});
