/// Map Tile Service — Manages offline tile caching via FMTC.
///
/// Initializes the FMTC backend at app startup and provides access
/// to tile stores for offline map usage. Ghana-first: passengers
/// need maps even without internet.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Default store name for general map tiles.
const String kDefaultTileStoreName = 'roadguard_tiles';

/// Service for managing offline map tile caching.
///
/// Uses FMTC (flutter_map_tile_caching) with ObjectBox backend
/// for fast, reliable offline tile storage.
class MapTileService {
  MapTileService._();
  static final MapTileService instance = MapTileService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the FMTC backend.
  ///
  /// Must be called once at app startup before any map widget is used.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await FMTCObjectBoxBackend().initialise();
      await _ensureDefaultStore();
      _isInitialized = true;
      debugPrint('MapTileService: FMTC initialized successfully');
    } catch (e) {
      debugPrint('MapTileService: FMTC init failed: $e');
      // Non-fatal — app works without offline tiles, just slower
    }
  }

  /// Ensure the default tile store exists.
  Future<void> _ensureDefaultStore() async {
    final store = FMTCStore(kDefaultTileStoreName);
    final isReady = await store.manage.ready;
    if (!isReady) {
      await store.manage.create();
    }
    debugPrint('MapTileService: Default store ready');
  }

  /// Get the default FMTC tile store for use with FlutterMap.
  FMTCStore get defaultStore => FMTCStore(kDefaultTileStoreName);

  /// Get tile stats for a store (tile count, size).
  Future<({int tileCount, double sizeMB})> getStoreStats([
    String storeName = kDefaultTileStoreName,
  ]) async {
    final store = FMTCStore(storeName);
    final stats = await store.stats.all;
    return (
      tileCount: stats.length,
      sizeMB: stats.size / 1024,
    );
  }

  /// Delete all cached tiles for a store.
  Future<void> clearStore([
    String storeName = kDefaultTileStoreName,
  ]) async {
    final store = FMTCStore(storeName);
    await store.manage.reset();
    debugPrint('MapTileService: Store "$storeName" cleared');
  }

  /// Delete all tile stores and reset FMTC completely.
  Future<void> resetAll() async {
    await FMTCObjectBoxBackend().uninitialise(deleteRoot: true);
    _isInitialized = false;
    debugPrint('MapTileService: All stores reset');
    // Re-initialize after reset
    await initialize();
  }
}

/// Riverpod provider for MapTileService.
final mapTileServiceProvider = Provider<MapTileService>((ref) {
  return MapTileService.instance;
});
