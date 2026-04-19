import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../network/connectivity_service.dart';

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

  void enqueue(Map<String, dynamic> action) {
    _queue.add(action);
    _recalc();
    // Fire and forget
    Future.microtask(flush);
  }

  Future<void> flush() async {
    final online = _ref.read(connectivityServiceProvider).status == NetworkStatus.online;
    if (!online || _queue.isEmpty) return;
    state = state.copyWith(state: SyncState.syncing);
    try {
      // Simulate server push with a short delay per item.
      final keys = _queue.keys.toList();
      for (final k in keys) {
        await Future.delayed(const Duration(milliseconds: 150));
        await _queue.delete(k);
      }
      state = SyncStatus(
        state: SyncState.idle,
        pending: 0,
        lastSync: DateTime.now(),
      );
    } catch (_) {
      state = state.copyWith(state: SyncState.error);
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
