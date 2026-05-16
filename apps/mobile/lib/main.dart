import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/tile_cache_service.dart';
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
    // Note: Push notifications will be disabled.
  }
  await TileCacheService.init();
  await TileCacheService.ensureStores();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  final container = ProviderContainer();
  await container.read(pushNotificationProvider).init();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const PetaliaApp(),
  ));
}
