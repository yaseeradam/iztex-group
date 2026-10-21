import 'package:hive_flutter/hive_flutter.dart';

class PendingSyncTracker {
  static const _boxName = 'pending_sync_ids';
  static const _deleteBoxName = 'pending_delete_ids';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
    await Hive.openBox(_deleteBoxName);
  }

  static Box get _box => Hive.box(_boxName);
  static Box get _deleteBox => Hive.box(_deleteBoxName);

  /// Mark a record as needing sync.
  /// [collection] is the Firestore collection name, e.g. 'ledger_entries'
  /// [id] is the record's unique ID
  static void markPending(String collection, String id) {
    // If it was queued for deletion, cancel deletion
    final pendingDeletes = getPendingDeleteIds(collection);
    if (pendingDeletes.contains(id)) {
      pendingDeletes.remove(id);
      _deleteBox.put(collection, pendingDeletes);
    }

    final existing = getPendingIds(collection);
    if (!existing.contains(id)) {
      _box.put(collection, [...existing, id]);
    }
  }

  /// Mark a record as synced (remove from pending list)
  static void markSynced(String collection, String id) {
    final existing = getPendingIds(collection);
    if (existing.remove(id)) {
      _box.put(collection, existing);
    }
  }

  /// Mark a record as pending deletion from cloud
  static void markPendingDelete(String collection, String id) {
    final pendingUpserts = getPendingIds(collection);
    if (pendingUpserts.contains(id)) {
      pendingUpserts.remove(id);
      _box.put(collection, pendingUpserts);
    }

    final existing = getPendingDeleteIds(collection);
    if (!existing.contains(id)) {
      _deleteBox.put(collection, [...existing, id]);
    }
  }

  /// Mark a deleted record as synced with cloud
  static void markDeleteSynced(String collection, String id) {
    final existing = getPendingDeleteIds(collection);
    if (existing.remove(id)) {
      _deleteBox.put(collection, existing);
    }
  }

  /// Get all IDs pending deletion for a given collection
  static List<String> getPendingDeleteIds(String collection) {
    final raw = _deleteBox.get(collection);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  /// Check if a specific item is queued for deletion
  static bool isPendingDelete(String collection, String id) {
    return getPendingDeleteIds(collection).contains(id);
  }

  /// Get all IDs pending sync for a given collection
  static List<String> getPendingIds(String collection) {
    final raw = _box.get(collection);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  /// Mark all IDs in a collection as synced
  static void clearCollection(String collection) {
    _box.put(collection, <String>[]);
    _deleteBox.put(collection, <String>[]);
  }

  /// Check if there are any pending records across all collections
  static bool hasPending() {
    for (final key in _box.keys) {
      final ids = getPendingIds(key.toString());
      if (ids.isNotEmpty) return true;
    }
    for (final key in _deleteBox.keys) {
      final ids = getPendingDeleteIds(key.toString());
      if (ids.isNotEmpty) return true;
    }
    return false;
  }
}
