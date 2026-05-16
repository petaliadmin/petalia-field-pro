import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../network/connectivity_service.dart';
import '../network/dio_provider.dart';

enum SyncState { idle, syncing, error }

class SyncStatus {
  final SyncState state;
  final int pending;
  final DateTime? lastSync;
  const SyncStatus({this.state = SyncState.idle, this.pending = 0, this.lastSync});

  SyncStatus copyWith({SyncState? state, int? pending, DateTime? lastSync}) =>
      SyncStatus(
        state: state ?? this.state,
        pending: pending ?? this.pending,
        lastSync: lastSync ?? this.lastSync,
      );
}

class SyncService extends StateNotifier<SyncStatus> {
  SyncService(this._ref) : super(const SyncStatus()) {
    _recalc();
    _sub = _ref.read(connectivityServiceProvider).stream.listen((status) {
      if (status == NetworkStatus.online) flush();
    });
  }

  final Ref _ref;
  late final StreamSubscription _sub;

  Box get _queue => Hive.box(AppConstants.boxSyncQueue);

  Future<void> enqueue(Map<String, dynamic> action) async {
    final op = action['op'] as String?;
    final id = action['id'] as String?;

    // Last Write Wins (Client-side optimization):
    // Si une opération identique sur le même ID est déjà dans la file,
    // on la remplace pour éviter d'envoyer des états obsolètes.
    if (op != null && id != null) {
      final existingKey = _findExistingActionKey(op, id);
      if (existingKey != null) {
        await _queue.put(existingKey, action);
        _recalc();
        await flush();
        return;
      }
    }

    await _queue.add(action);
    _recalc();
    await flush();
  }

  dynamic _findExistingActionKey(String op, String id) {
    for (final key in _queue.keys) {
      final val = _queue.get(key);
      if (val is Map && val['op'] == op && val['id'] == id) {
        return key;
      }
    }
    return null;
  }

  Future<void> flush() async {
    final online = _ref.read(connectivityServiceProvider).status ==
        NetworkStatus.online;
    if (!online || _queue.isEmpty) return;
    if (state.state == SyncState.syncing) return;
    
    state = state.copyWith(state: SyncState.syncing);
    final dio = _ref.read(dioProvider);
    
    try {
      final keys = _queue.keys.toList();
      final isDataSaver = Hive.box(AppConstants.boxSettings)
          .get(AppConstants.kDataSaverMode, defaultValue: false) as bool;
      final isWifi = _ref.read(connectivityServiceProvider).isWifi;

      for (final k in keys) {
        final action = _queue.get(k) as Map;
        
        // Optimisation Lite : Si mode économie data actif et pas Wi-Fi, 
        // on saute les uploads d'observations (images/audios)
        if (isDataSaver && !isWifi && action['op'] == 'create_observation') {
          continue;
        }

        // Tentative d'envoi réel
        await _pushItem(dio, action);
        
        // Succès -> on supprime de la file locale
        await _queue.delete(k);
      }
      
      state = SyncStatus(
        state: SyncState.idle,
        pending: 0,
        lastSync: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('SyncService.flush failed: $e\n$st');
      // On passe en erreur mais on garde les éléments dans la file pour le prochain flush
      state = state.copyWith(state: SyncState.error);
    }
  }

  Future<void> _pushItem(dynamic dio, Map action) async {
    final op = action['op'] as String;
    final id = action['id'] as String;
    
    // Mapping opération -> endpoint
    switch (op) {
      case 'upsert_parcel':
        final rawParcel = action['parcel'] as Map<String, dynamic>?;
        if (rawParcel == null) {
          debugPrint('[SYNC] upsert_parcel action missing "parcel" data. Skipping legacy/malformed item.');
          return;
        }
        final boundary = (rawParcel['boundary'] as List?) ?? [];
        
        // Conversion LatLng (lat, lon) -> GeoJSON (lon, lat)
        final coords = boundary.map((p) => [p[1], p[0]]).toList();
        
        // Fermer l'anneau du polygone si nécessaire
        if (coords.isNotEmpty && (coords.first[0] != coords.last[0] || coords.first[1] != coords.last[1])) {
          coords.add(coords.first);
        }

        final payload = {
          ...rawParcel,
          'boundary': coords.length >= 4 ? {
            'type': 'Polygon',
            'coordinates': [coords],
          } : null,
        };

        await dio.post(
          '/parcels', 
          data: payload,
          options: Options(headers: {'x-idempotency-key': id}),
        );
        break;
      case 'delete_parcel':
        await dio.delete(
          '/parcels/$id',
          options: Options(headers: {'x-idempotency-key': 'DEL_$id'}),
        );
        break;
      case 'create_expert_request':
        await dio.post('/experts/request', data: {
          'id': action['id'],
          'parcelId': action['parcelId'],
          'context': action['context'],
        });
        break;
      case 'create_observation':
        final obsId = action['id'] as String;
        final obsData = Hive.box(AppConstants.boxObservations).get(obsId);
        if (obsData == null) {
          debugPrint('[SYNC] Observation $obsId not found in local DB. Skipping.');
          return;
        }

        final photosList = <MultipartFile>[];
        if (kIsWeb) {
          final pBytes = (obsData['photoBytes'] as List?) ?? [];
          final pPaths = (obsData['photoPaths'] as List?) ?? [];
          for (int i = 0; i < pBytes.length; i++) {
            final filename = pPaths.length > i ? pPaths[i].split('/').last : 'photo_$i.jpg';
            photosList.add(MultipartFile.fromBytes(pBytes[i] as Uint8List, filename: filename));
          }
        } else {
          final pPaths = (obsData['photoPaths'] as List?) ?? [];
          for (final path in pPaths) {
            photosList.add(MultipartFile.fromFileSync(path, filename: path.split('/').last));
          }
        }

        final audiosList = <MultipartFile>[];
        if (!kIsWeb) {
          final aPaths = (obsData['audioPaths'] as List?) ?? [];
          for (final path in aPaths) {
            audiosList.add(MultipartFile.fromFileSync(path, filename: path.split('/').last));
          }
        }

        final formData = FormData.fromMap({
          ...obsData,
          'photos': photosList,
          'audios': audiosList,
        });

        await dio.post(
          '/parcels/observations', 
          data: formData,
          options: Options(headers: {'x-idempotency-key': obsId}),
        );
        break;
      default:
        debugPrint('Unknown sync operation: $op');
    }
  }

  void _recalc() {
    state = state.copyWith(pending: _queue.length);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final syncServiceProvider =
    StateNotifierProvider<SyncService, SyncStatus>((ref) => SyncService(ref));
