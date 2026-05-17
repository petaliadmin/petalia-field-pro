import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../network/connectivity_service.dart';
import '../network/dio_provider.dart';
import '../../features/parcels/presentation/parcels_providers.dart';
import '../../features/wallet/presentation/wallet_providers.dart';
import './credit_service.dart';
import '../../features/auth/presentation/auth_providers.dart';

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
      if (status == NetworkStatus.online) {
        flush();
        reconcileAll();
      }
    });
  }

  final Ref _ref;
  late final StreamSubscription _sub;

  Future<void> reconcileAll() async {
    final online = _ref.read(connectivityServiceProvider).status == NetworkStatus.online;
    if (!online || !AppConstants.remoteApiEnabled) return;

    final authState = _ref.read(authStateProvider).value;
    if (authState == null || !authState.isAuthenticated) return;

    debugPrint('[SYNC] Lancement de la réconciliation systématique des données depuis l\'API...');
    try {
      // 1. Réconciliation des Parcelles
      await _ref.read(parcelsProvider.notifier).fetchRemoteParcels(forceFull: true);

      // 2. Réconciliation du Solde et de l'historique Wallet
      await _ref.read(creditServiceProvider.notifier).refreshBalance();
      _ref.invalidate(walletTransactionsProvider);

      debugPrint('[SYNC] Réconciliation systématique terminée avec succès.');
    } catch (e, st) {
      debugPrint('[SYNC] Erreur lors de la réconciliation systématique: $e\n$st');
    }
  }

  Box get _queue => Hive.box(AppConstants.boxSyncQueue);
  Box get _queueMedia => Hive.box(AppConstants.boxSyncQueueMedia);

  Future<void> enqueue(Map<String, dynamic> action) async {
    final op = action['op'] as String?;
    final id = action['id'] as String?;
    final isMedia = op == 'create_observation';
    final targetQueue = isMedia ? _queueMedia : _queue;

    // Last Write Wins (Client-side optimization):
    if (op != null && id != null) {
      final existingKey = _findExistingActionKey(targetQueue, op, id);
      if (existingKey != null) {
        await targetQueue.put(existingKey, action);
        _recalc();
        await flush();
        return;
      }
    }

    await targetQueue.add(action);
    _recalc();
    await flush();
  }

  dynamic _findExistingActionKey(Box q, String op, String id) {
    for (final key in q.keys) {
      final val = q.get(key);
      if (val is Map && val['op'] == op && val['id'] == id) {
        return key;
      }
    }
    return null;
  }

  Future<void> flush() async {
    final online = _ref.read(connectivityServiceProvider).status ==
        NetworkStatus.online;
    if (!online || (_queue.isEmpty && _queueMedia.isEmpty)) return;
    if (state.state == SyncState.syncing) return;
    
    state = state.copyWith(state: SyncState.syncing);
    final dio = _ref.read(dioProvider);
    
    try {
      // 1. Flush Data Queue (Priority)
      final dataKeys = _queue.keys.toList();
      for (final k in dataKeys) {
        final action = _queue.get(k) as Map;
        await _pushItem(dio, action);
        await _queue.delete(k);
      }

      // 2. Flush Media Queue (Secondary)
      final isDataSaver = Hive.box(AppConstants.boxSettings)
          .get(AppConstants.kDataSaverMode, defaultValue: false) as bool;
      final isWifi = _ref.read(connectivityServiceProvider).isWifi;

      final mediaKeys = _queueMedia.keys.toList();
      for (final k in mediaKeys) {
        final action = _queueMedia.get(k) as Map;
        if (isDataSaver && !isWifi) {
          continue; // Skip media upload if Data Saver is ON and no WiFi
        }
        await _pushItem(dio, action);
        await _queueMedia.delete(k);
      }
      
      _recalc();
      state = SyncStatus(
        state: SyncState.idle,
        pending: _queue.length + _queueMedia.length,
        lastSync: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('SyncService.flush failed: $e\n$st');
      state = state.copyWith(state: SyncState.error);
    }
  }

  Future<void> _pushItem(dynamic dio, Map action) async {
    final op = action['op'] as String;
    final id = action['id'] as String;
    
    switch (op) {
      case 'upsert_parcel':
        final rawParcel = action['parcel'] as Map<String, dynamic>?;
        if (rawParcel == null) {
          debugPrint('[SYNC] upsert_parcel action missing "parcel" data. Skipping legacy/malformed item.');
          return;
        }
        final boundary = (rawParcel['boundary'] as List?) ?? [];
        
        final coords = boundary.map((p) => [p[1], p[0]]).toList();
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
      case 'wallet_tx':
        await dio.post(
          '/wallet/sync_tx',
          data: {
            'id': action['id'],
            'amount': action['amount'],
            'description': action['description'],
          },
          options: Options(headers: {'x-idempotency-key': action['id']}),
        );
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
    state = state.copyWith(pending: _queue.length + _queueMedia.length);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final syncServiceProvider =
    StateNotifierProvider<SyncService, SyncStatus>((ref) => SyncService(ref));
