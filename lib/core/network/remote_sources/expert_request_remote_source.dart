/// Source d'envoi des demandes d'aide expert — abstraction permettant de
/// brancher un backend plus tard.
///
/// Aujourd'hui :
/// - [LocalExpertRequestRemoteSource] : file d'attente Hive — la demande
///   est stockée localement, listable en "À envoyer". La sync (§4.1) la
///   pousse le jour où le backend existe.
/// - [HttpExpertRequestRemoteSource] : stub HTTP prêt à basculer.
library;

import 'package:dio/dio.dart';

import '../../../features/recommendations/domain/expert_request.dart';

abstract class ExpertRequestRemoteSource {
  /// Publie une demande d'expert. Retourne la demande éventuellement
  /// enrichie (ex: identifiant distant, timestamp serveur). Tant que
  /// l'impl est locale, la demande est simplement renvoyée telle quelle
  /// (elle sera poussée plus tard via la sync queue).
  Future<ExpertRequest> submit(ExpertRequest request);
}

/// Impl locale — ne fait que persister l'état `queued`. C'est le repository
/// qui insère dans la box Hive avant d'appeler cette source.
class LocalExpertRequestRemoteSource implements ExpertRequestRemoteSource {
  const LocalExpertRequestRemoteSource();

  @override
  Future<ExpertRequest> submit(ExpertRequest request) async {
    // Aucun appel réseau — on marque la demande comme en attente de sync.
    return request.copyWith(status: ExpertRequestStatus.queued);
  }
}

/// Stub HTTP — le endpoint attendu (non déployé) :
///
///   POST {baseUrl}/v1/expert_requests
///   201 Created
///   { "id": "...", "status": "received", "receivedAt": "..." }
class HttpExpertRequestRemoteSource implements ExpertRequestRemoteSource {
  HttpExpertRequestRemoteSource(this._dio);
  final Dio _dio;

  @override
  Future<ExpertRequest> submit(ExpertRequest request) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/v1/expert_requests',
      data: request.toJson(),
    );
    final data = resp.data ?? const {};
    return request.copyWith(
      remoteId: data['id'] as String?,
      status: ExpertRequestStatus.sent,
    );
  }
}
