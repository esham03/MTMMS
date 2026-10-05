import 'package:flutter/foundation.dart';

/// Centralized Real-time Data Synchronization Service for MTMMS.
///
/// Features:
/// - Instant cross-screen state broadcast when any entity is created, updated, or deleted
/// - Seamless background sync without requiring re-authentication or app restarts
class DataSyncService {
  DataSyncService._();

  /// Global reactive notifier incremented whenever backend data changes.
  static final ValueNotifier<int> syncNotifier = ValueNotifier<int>(0);

  /// Broadcasts a data change event to all active screens.
  static void notifyDataChanged() {
    syncNotifier.value++;
    debugPrint('[MTMMS DataSyncService] Live sync notification dispatched (v${syncNotifier.value})');
  }
}
