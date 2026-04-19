/// Source de règles agronomiques — abstraction permettant de brancher une
/// API distante ultérieurement sans toucher au moteur de recommandation.
///
/// Deux implémentations :
/// - [LocalAgroRulesRemoteSource] : lecture depuis l'asset bundle JSON
///   (`assets/agro_rules/agro_rules.json`). Impl utilisée par défaut.
/// - [HttpAgroRulesRemoteSource] : stub HTTP prêt à consommer un endpoint
///   `GET /v1/agro_rules`. Activé dès que [AppConstants.remoteApiEnabled].
///   Aucun endpoint n'est encore déployé — la classe est en place pour
///   minimiser le travail le jour où le backend existe.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../features/recommendations/domain/agro_rule.dart';

/// Contrat commun — une seule méthode : charger l'ensemble des règles
/// disponibles. La mise en cache éventuelle (Hive) est du ressort du
/// repository, pas de la source.
abstract class AgroRulesRemoteSource {
  Future<List<AgroRule>> fetchAll();
}

/// Implémentation par défaut — lit le fichier JSON embarqué dans les assets.
class LocalAgroRulesRemoteSource implements AgroRulesRemoteSource {
  static const String _assetPath = 'assets/agro_rules/agro_rules.json';

  const LocalAgroRulesRemoteSource();

  @override
  Future<List<AgroRule>> fetchAll() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final rules = (decoded['rules'] as List)
        .cast<Map<String, dynamic>>()
        .map(AgroRule.fromJson)
        .toList(growable: false);
    return rules;
  }
}

/// Stub HTTP — prêt à être branché sur un backend.
///
/// Le endpoint attendu (non déployé aujourd'hui) :
///
///   GET {baseUrl}/v1/agro_rules?since={ISO8601}
///   200 OK
///   { "schemaVersion": 1, "updatedAt": "...", "rules": [ ... ] }
///
/// La clause `since` permettra, le moment venu, d'implémenter une sync
/// différentielle. Tant que le backend n'existe pas, cette classe n'est
/// jamais instanciée (AppConstants.remoteApiEnabled == false).
class HttpAgroRulesRemoteSource implements AgroRulesRemoteSource {
  HttpAgroRulesRemoteSource(this._dio);
  final Dio _dio;

  @override
  Future<List<AgroRule>> fetchAll() async {
    final resp = await _dio.get<Map<String, dynamic>>('/v1/agro_rules');
    final data = resp.data ?? const {};
    final rules = ((data['rules'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(AgroRule.fromJson)
        .toList(growable: false);
    return rules;
  }
}
