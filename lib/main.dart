import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/fake_api/fake_data.dart';
import 'core/services/tile_cache_service.dart';
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await TileCacheService.init();
  await TileCacheService.ensureStores();
  await _seedOnFirstRun();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: PetaliaApp()));
}

Future<void> _seedOnFirstRun() async {
  final box = Hive.box(AppConstants.boxParcels);
  if (box.isEmpty) {
    for (final p in FakeData.seedParcels()) {
      await box.put(p['id'], p);
    }
  }
  final alerts = Hive.box(AppConstants.boxAlerts);
  if (alerts.isEmpty) {
    for (final a in FakeData.seedAlerts()) {
      await alerts.put(a['id'], a);
    }
  }
}
