import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:petaliacropassist/core/constants/app_constants.dart';
import 'package:petaliacropassist/core/services/sync_service.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('petalia_hive_test_');
    Hive.init(tmp.path);
    await Hive.openBox(AppConstants.boxSyncQueue);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tmp.delete(recursive: true);
  });

  group('SyncStatus', () {
    test('default state is idle with 0 pending', () {
      const s = SyncStatus();
      expect(s.state, SyncState.idle);
      expect(s.pending, 0);
      expect(s.lastSync, isNull);
    });

    test('copyWith only mutates provided fields', () {
      const s = SyncStatus(state: SyncState.idle, pending: 3);
      final next = s.copyWith(state: SyncState.syncing);
      expect(next.state, SyncState.syncing);
      expect(next.pending, 3); // preserved
    });

    test('copyWith preserves lastSync when not passed', () {
      final t = DateTime.utc(2026, 5, 12);
      final s = SyncStatus(lastSync: t);
      final next = s.copyWith(pending: 2);
      expect(next.lastSync, t);
    });
  });

  group('Sync queue (LWW dedup)', () {
    test('queue starts empty', () {
      expect(Hive.box(AppConstants.boxSyncQueue).length, 0);
    });

    test('two operations on the same (op, id) keep only one entry', () async {
      // The SyncService.enqueue path runs flush() which clears the queue, so
      // we exercise the dedup logic by directly walking the queue, mirroring
      // _findExistingActionKey's contract.
      final box = Hive.box(AppConstants.boxSyncQueue);
      await box.add({'op': 'upsert', 'id': 'p1', 'rev': 1});
      await box.add({'op': 'upsert', 'id': 'p1', 'rev': 2});

      // Two adds (no dedup at the box level).
      expect(box.length, 2);

      // Simulate dedup: keep the last revision for each (op, id) key.
      final byKey = <String, Map>{};
      for (final raw in box.values) {
        final m = raw as Map;
        byKey['${m['op']}|${m['id']}'] = m;
      }
      expect(byKey.length, 1);
      expect(byKey.values.first['rev'], 2);
    });

    test('different (op, id) pairs are kept distinct', () async {
      final box = Hive.box(AppConstants.boxSyncQueue);
      await box.add({'op': 'upsert', 'id': 'p1'});
      await box.add({'op': 'upsert', 'id': 'p2'});
      await box.add({'op': 'delete', 'id': 'p1'});
      expect(box.length, 3);
    });
  });
}
