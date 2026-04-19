/// Providers Riverpod des sources distantes — bascule automatique entre
/// implémentation locale (assets/Hive) et implémentation HTTP (Dio).
///
/// La bascule est pilotée par [AppConstants.remoteApiEnabled] :
/// - `false` (défaut) → impl locale, pas d'appel réseau.
/// - `true` (via `--dart-define=PETALIA_REMOTE_BASE_URL=...`) → impl HTTP.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../dio_client.dart';
import 'agro_rules_remote_source.dart';
import 'expert_request_remote_source.dart';

/// Client Dio partagé — instancié uniquement si le backend est activé.
/// Reste `null` en mode local (pas de baseUrl, pas d'interceptors chargés).
final remoteDioProvider = Provider<DioClient?>((ref) {
  if (!AppConstants.remoteApiEnabled) return null;
  return DioClient.create(baseUrl: AppConstants.remoteBaseUrl);
});

final agroRulesRemoteSourceProvider = Provider<AgroRulesRemoteSource>((ref) {
  final dio = ref.watch(remoteDioProvider);
  if (dio == null) return const LocalAgroRulesRemoteSource();
  return HttpAgroRulesRemoteSource(dio.instance);
});

final expertRequestRemoteSourceProvider =
    Provider<ExpertRequestRemoteSource>((ref) {
  final dio = ref.watch(remoteDioProvider);
  if (dio == null) return const LocalExpertRequestRemoteSource();
  return HttpExpertRequestRemoteSource(dio.instance);
});
