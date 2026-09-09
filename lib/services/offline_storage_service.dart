// =============================================================================
// lib/services/offline_storage_service.dart
// CPI Offline Storage & Data Sync Engine
// Handles local caching with Hive, network monitoring, and queued offline sync.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';

class OfflineStorageService {
  static late Box _cacheBox;
  static late Box _syncQueueBox;
  static late Box _settingsBox;

  static final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static bool _isSyncing = false;

  // Cache Keys
  static const String keyTeachers = 'cached_teachers';
  static const String keyStudents = 'cached_students';
  static const String keyNotices = 'cached_notices';
  static const String keyRoutine = 'cached_routine';
  static const String keyResults = 'cached_results';
  static const String keyApplications = 'cached_applications';
  static const String keyDashboardStats = 'cached_dashboard_stats';
  static const String keyActivities = 'cached_recent_activities';
  static const String keyThemeMode = 'isDarkMode';

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Initialize Hive and boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('cpi_data_cache');
    _syncQueueBox = await Hive.openBox('cpi_sync_queue');
    _settingsBox = await Hive.openBox('cpi_settings');

    // Initial connectivity check
    final initialResults = await Connectivity().checkConnectivity();
    _updateOnlineStatus(initialResults);

    // Listen to network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _updateOnlineStatus(results);
    });

    debugPrint('✅ OfflineStorageService initialized');
  }

  static void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOnline = isOnlineNotifier.value;
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    isOnlineNotifier.value = hasConnection;

    if (hasConnection && !wasOnline) {
      debugPrint('🔄 Network reconnected - processing sync queue...');
      processSyncQueue();
    }

    debugPrint('🌐 Connectivity: ${hasConnection ? 'ONLINE' : 'OFFLINE'}');
  }

  // ===========================================================================
  // CONNECTIVITY GETTERS
  // ===========================================================================

  static bool get isOnline => isOnlineNotifier.value;

  static bool get isOffline => !isOnlineNotifier.value;

  static int get pendingSyncCount => _syncQueueBox.length;

  // ===========================================================================
  // DATA CACHING
  // ===========================================================================

  /// Cache arbitrary JSON data
  static Future<void> cacheData(String key, dynamic data) async {
    try {
      await _cacheBox.put(key, data);
    } catch (e) {
      debugPrint('⚠️ Error caching data for key $key: $e');
    }
  }

  /// Retrieve cached JSON data
  static dynamic getCachedData(String key, {dynamic defaultValue}) {
    try {
      return _cacheBox.get(key, defaultValue: defaultValue);
    } catch (e) {
      debugPrint('⚠️ Error reading cached data for key $key: $e');
      return defaultValue;
    }
  }

  /// Clear specific cache key
  static Future<void> removeCache(String key) async {
    await _cacheBox.delete(key);
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    await _cacheBox.clear();
  }

  // ===========================================================================
  // SETTINGS STORAGE
  // ===========================================================================

  static Future<void> setDarkMode(bool isDark) async {
    await _settingsBox.put(keyThemeMode, isDark);
  }

  static bool getDarkMode({bool defaultValue = true}) {
    return _settingsBox.get(keyThemeMode, defaultValue: defaultValue) as bool;
  }

  static ValueListenable<Box> getSettingsListenable() {
    return _settingsBox.listenable();
  }

  // ===========================================================================
  // OFFLINE SYNC QUEUE
  // ===========================================================================

  /// Add an operation to the offline sync queue (POSITIONAL PARAMETERS)
  /// [operation] - Map containing 'table', 'action', 'id', 'data'
  static Future<void> addToSyncQueue(Map<String, dynamic> operation) async {
    try {
      final entry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'operation': operation,
      };

      await _syncQueueBox.put(entry['id'], entry);
      debugPrint(
        '📦 Stored offline action: ${operation['action']} on ${operation['table']} (queue size: ${_syncQueueBox.length})',
      );
    } catch (e) {
      debugPrint('⚠️ Error adding to sync queue: $e');
    }
  }

  /// Get all queued operations
  static List<Map<String, dynamic>> getSyncQueue() {
    return _syncQueueBox.values
        .map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  /// Remove a specific item from the sync queue
  static Future<void> removeFromSyncQueue(String id) async {
    try {
      await _syncQueueBox.delete(id);
      debugPrint('✅ Removed sync queue item: $id');
    } catch (e) {
      debugPrint('⚠️ Error removing sync queue item: $e');
    }
  }

  /// Clear the entire sync queue
  static Future<void> clearSyncQueue() async {
    try {
      await _syncQueueBox.clear();
      debugPrint('✅ Sync queue cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing sync queue: $e');
    }
  }

  /// Process the sync queue when back online
  static Future<void> processSyncQueue() async {
    if (_isSyncing || !isOnline || _syncQueueBox.isEmpty) return;

    _isSyncing = true;
    debugPrint(
      '🔄 Processing offline sync queue (${_syncQueueBox.length} items)...',
    );

    final client = SupabaseService.client;
    final keysToDelete = <String>[];

    // Get all items from the queue
    final allItems = _syncQueueBox.values.toList();
    final allKeys = _syncQueueBox.keys.toList();

    for (int i = 0; i < allItems.length; i++) {
      final rawItem = allItems[i];
      if (rawItem == null || rawItem is! Map) {
        keysToDelete.add(allKeys[i].toString());
        continue;
      }

      final entry = Map<String, dynamic>.from(rawItem);
      final operation = entry['operation'] as Map<String, dynamic>?;

      if (operation == null) {
        keysToDelete.add(allKeys[i].toString());
        continue;
      }

      final action = operation['action'] as String?;
      final table = operation['table'] as String?;
      final data = operation['data'] as Map<String, dynamic>?;
      final id = operation['id'] as String?;

      if (table == null || action == null) {
        keysToDelete.add(allKeys[i].toString());
        continue;
      }

      try {
        if (action == 'insert' && data != null) {
          // Remove any id that might conflict
          data.remove('id');
          await client.from(table).insert(data);
          debugPrint('✅ Synced INSERT on $table');
        } else if (action == 'update' && data != null && id != null) {
          await client.from(table).update(data).eq('id', id);
          debugPrint('✅ Synced UPDATE on $table (id: $id)');
        } else if (action == 'delete' && id != null) {
          await client.from(table).delete().eq('id', id);
          debugPrint('✅ Synced DELETE on $table (id: $id)');
        }

        keysToDelete.add(allKeys[i].toString());
      } catch (e) {
        debugPrint('❌ Failed to sync item on $table: $e');
        // Stop batch sync if network failed
        if (!isOnline) break;
      }
    }

    // Delete successfully processed items
    for (final key in keysToDelete) {
      await _syncQueueBox.delete(key);
    }

    _isSyncing = false;
    debugPrint('🏁 Sync queue finished. Remaining: ${_syncQueueBox.length}');
  }

  /// Manually trigger sync queue processing
  static Future<void> flushSyncQueueNow() async {
    if (!isOnline) {
      debugPrint('⏳ Cannot flush sync queue - offline');
      return;
    }
    await processSyncQueue();
  }

  /// Dispose resources
  static void dispose() {
    _connectivitySubscription?.cancel();
  }
}
