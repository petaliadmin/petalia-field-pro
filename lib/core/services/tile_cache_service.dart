import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../utils/bounds_utils.dart';

/// Stores managed by FMTC.
class TileStores {
  TileStores._();
  static const osm = 'osm';
  static const satellite = 'satellite';
  static const ndvi = 'ndvi';
  static const all = [osm, satellite];
}

/// Whether FMTC (native tile caching) is supported.
bool get isFmtcSupported =>
    !kIsWeb &&
    (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux);

/// Manages offline tile caching via FMTC.
/// Falls back gracefully on unsupported platforms (web).
class TileCacheService {
  TileCacheService._();

  static bool _initialized = false;

  // ───────── Lifecycle ─────────

  static Future<void> init() async {
    if (_initialized) return;

    // FMTC requires native platform - skip on web
    if (!isFmtcSupported) return;

    try {
      await FMTCObjectBoxBackend().initialise();
      _initialized = true;
    } catch (e) {
      debugPrint('FMTC init failed: $e');
    }
  }

  static Future<void> ensureStores() async {
    if (!isFmtcSupported) return;

    for (final name in TileStores.all) {
      final store = FMTCStore(name);
      if (!await store.manage.ready) {
        await store.manage.create();
      }
    }
  }

  // ───────── Direct URLs ─────────

  /// Direct tile URL for a store (no FMTC).
  static String tileUrlFor(String storeName) {
    switch (storeName) {
      case TileStores.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case TileStores.ndvi:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  // ───────── Tile provider ─────────

  /// Get cached tile provider.
  /// On native: uses FMTC. On web: returns URL string (network only).
  /// This method returns either String or FMTCTileProvider.
  static dynamic tileProviderFor(String storeName) {
    final url = tileUrlFor(storeName);

    // On web without FMTC support, return URL string
    if (!isFmtcSupported) {
      return url;
    }

    try {
      return FMTCStore(storeName).getTileProvider(
        settings: FMTCTileProviderSettings(
          behavior: CacheBehavior.cacheFirst,
          cachedValidDuration: const Duration(days: 30),
        ),
      );
    } catch (e) {
      // Fallback to network only
      return url;
    }
  }

  // ───────── Bulk download ─────────

  static Stream<DownloadProgress> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String storeName,
    required String urlTemplate,
  }) {
    if (!isFmtcSupported) return const Stream.empty();
    final region = RectangleRegion(bounds).toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(urlTemplate: urlTemplate),
    );
    return FMTCStore(storeName).download.startForeground(
      region: region,
      parallelThreads: 3,
      skipExistingTiles: true,
      skipSeaTiles: true,
    );
  }

  static Future<int> checkRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String storeName,
    required String urlTemplate,
  }) async {
    if (!isFmtcSupported) return 0;
    final region = RectangleRegion(bounds).toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(urlTemplate: urlTemplate),
    );
    return FMTCStore(storeName).download.check(region);
  }

  static Future<void> cancelDownload(String storeName) async {
    if (!isFmtcSupported) return;
    await FMTCStore(storeName).download.cancel();
  }

  // ───────── Cache stats ─────────

  static Future<double> totalCacheSizeMb() async {
    if (!isFmtcSupported) return 0;
    double total = 0;
    for (final name in TileStores.all) {
      final stats = await FMTCStore(name).stats.all;
      total += stats.size;
    }
    return total / 1024.0;
  }

  static Future<Map<String, int>> tileCountByStore() async {
    if (!isFmtcSupported) return {};
    final result = <String, int>{};
    for (final name in TileStores.all) {
      final stats = await FMTCStore(name).stats.all;
      result[name] = stats.length;
    }
    return result;
  }

  static Future<void> clearAllCaches() async {
    if (!isFmtcSupported) return;
    for (final name in TileStores.all) {
      await FMTCStore(name).manage.reset();
    }
  }

  static Future<void> clearStore(String storeName) async {
    if (!isFmtcSupported) return;
    await FMTCStore(storeName).manage.reset();
  }

  // ───────── Auto-cache ─────────

  static const _parcelBufferKm = 2.0;
  static const _parcelMinZoom = 10;
  static const _parcelMaxZoom = 17;

  static void cacheAroundParcel({
    required List<LatLng> boundary,
    required String osmUrl,
  }) {
    if (boundary.length < 3 || !isFmtcSupported) return;
    final bounds = BoundsUtils.boundsFromPoints(
      boundary,
      bufferKm: _parcelBufferKm,
    );
    _activeDownload?.cancel();
    final sub =
        downloadRegion(
          bounds: bounds,
          minZoom: _parcelMinZoom,
          maxZoom: _parcelMaxZoom,
          storeName: TileStores.osm,
          urlTemplate: osmUrl,
        ).listen(
          (progress) {
            _downloadController.add(progress);
            if (progress.isComplete) _downloadController.add(null);
          },
          onError: (_) => _downloadController.add(null),
          onDone: () => _downloadController.add(null),
        );
    _activeDownload = sub;
  }

  static StreamSubscription<DownloadProgress>? _activeDownload;
  static final _downloadController =
      StreamController<DownloadProgress?>.broadcast();
  static Stream<DownloadProgress?> get downloadProgress =>
      _downloadController.stream;
}

// ─────────────── Providers ───────────────

final tileDownloadProgressProvider = StreamProvider<DownloadProgress?>((ref) {
  return TileCacheService.downloadProgress;
});

final tileCacheSizeMbProvider = FutureProvider<double>((ref) {
  return TileCacheService.totalCacheSizeMb();
});

final tileCacheStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return TileCacheService.tileCountByStore();
});
