import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../datasources/product_local_datasource.dart';
import '../datasources/customer_local_datasource.dart';
import '../datasources/sale_local_datasource.dart';
import '../datasources/debt_local_datasource.dart';
import '../datasources/shop_customer_local_datasource.dart';
import '../../core/services/pending_sync_tracker.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../presentation/receive/receive_screen.dart';
import '../../presentation/sales_ledger/sales_ledger_screen.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/sale_model.dart';
import '../models/debt_model.dart';
import '../models/customer_ledger_model.dart';
import '../models/receive_order_model.dart';

enum SyncStatus { synced, syncing, pending, error }

class SyncService {
  final ProductLocalDataSource _productDS;
  final CustomerLocalDataSource _customerDS;
  final SaleLocalDataSource _saleDS;
  final DebtLocalDataSource _debtDS;
  final ShopCustomerLocalDataSource _shopCustomerDS;
  final String activeShopId;

  SyncStatus _status = SyncStatus.synced;
  SyncStatus get status => _status;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncService(
    this._productDS,
    this._customerDS,
    this._saleDS,
    this._debtDS,
    this._shopCustomerDS,
    this.activeShopId,
  );

  void dispose() {
    _statusController.close();
  }

  bool _isSyncing = false;

  Future<Box<T>> _getBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  Future<User?> _ensureAuth() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) return user;

    // Check if the user is authenticated locally in Hive
    final authBox = await _getBox('auth');
    final isLoggedIn = authBox.get('logged_in', defaultValue: false) as bool;
    if (isLoggedIn) {
      debugPrint('[SYNC] Re-authenticating Firebase Auth session...');
      const canonicalEmail = 'mlintex@gmail.com';
      const canonicalPass = 'mlintex123';
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: canonicalEmail,
          password: canonicalPass,
        );
        user = credential.user;
      } catch (e) {
        try {
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: canonicalEmail,
            password: canonicalPass,
          );
          user = credential.user;
        } catch (e2) {
          debugPrint('[SYNC AUTH ERROR] Re-authentication failed: $e2');
        }
      }
    }
    return user;
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final user = await _ensureAuth();
      if (user == null) {
        debugPrint('[SYNC ERROR] Cannot sync: user is not signed in to Firebase.');
        _setStatus(SyncStatus.error);
        return;
      }

      final userId = user.uid;
      final db = FirebaseFirestore.instance;
      debugPrint('[SYNC] Starting sync for user: $userId on shop: $activeShopId');

      // ============================================
      // 1. PUSH: LOCAL DATA TO FIRESTORE
      // ============================================

      // Push pending deletions first
      await _pushDeletions(db, userId, 'products_$activeShopId', 'products');
      await _pushDeletions(db, userId, 'customers_$activeShopId', 'customers');
      await _pushDeletions(db, userId, 'sales_$activeShopId', 'sales');
      await _pushDeletions(db, userId, 'debts_$activeShopId', 'debts');
      await _pushDeletions(db, userId, 'shop_customers_$activeShopId', 'shop_customers');

      // Model-based types (push all local data to cloud)
      final allProducts = await _productDS.getAllProducts();
      for (final p in allProducts) {
        final map = p.toMap();
        map['updatedAt'] = p.updatedAt.toIso8601String();
        await db.collection('users').doc(userId).collection('products').doc(p.id)
            .set(map, SetOptions(merge: true));
        await _productDS.markAsSynced(p.id);
      }

      final allCustomers = await _customerDS.getAllCustomers();
      for (final c in allCustomers) {
        final map = c.toMap();
        map['updatedAt'] = c.updatedAt.toIso8601String();
        await db.collection('users').doc(userId).collection('customers').doc(c.id)
            .set(map, SetOptions(merge: true));
        await _customerDS.markAsSynced(c.id);
      }

      final allSales = await _saleDS.getAllSales();
      for (final s in allSales) {
        final map = s.toMap();
        map['updatedAt'] = s.saleDate.toIso8601String();
        await db.collection('users').doc(userId).collection('sales').doc(s.id)
            .set(map, SetOptions(merge: true));
        await _saleDS.markAsSynced(s.id);
      }

      final allDebts = await _debtDS.getAllDebts();
      for (final d in allDebts) {
        final map = d.toMap();
        map['updatedAt'] = d.updatedAt.toIso8601String();
        await db.collection('users').doc(userId).collection('debts').doc(d.id)
            .set(map, SetOptions(merge: true));
        await _debtDS.markAsSynced(d.id);
      }

      final allShopCustomers = await _shopCustomerDS.getAllCustomers();
      for (final c in allShopCustomers) {
        final map = c.toMap();
        map['updatedAt'] = c.updatedAt.toIso8601String();
        await db.collection('users').doc(userId).collection('shop_customers').doc(c.id)
            .set(map, SetOptions(merge: true));
        await _shopCustomerDS.markAsSynced(c.id);
      }

      // Hive-native types via PendingSyncTracker & full local sync
      await _pushHiveNative<LedgerEntry>(db, userId, 'ledger_entries_$activeShopId', 'ledger_entries', (e) => {
        'id': e.id, 'customerId': e.customerId, 'date': e.date.toIso8601String(),
        'inItem': e.inItem, 'outItem': e.outItem, 'price': e.price, 'quantity': e.quantity,
        'totalAmount': e.totalAmount, 'runningBalance': e.runningBalance, 'typeIndex': e.typeIndex,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _pushHiveNative<LedgerEntry>(db, userId, 'shop_ledger_entries_$activeShopId', 'shop_ledger_entries', (e) => {
        'id': e.id, 'customerId': e.customerId, 'date': e.date.toIso8601String(),
        'inItem': e.inItem, 'outItem': e.outItem, 'price': e.price, 'quantity': e.quantity,
        'totalAmount': e.totalAmount, 'runningBalance': e.runningBalance, 'typeIndex': e.typeIndex,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _pushHiveNative<ReceiveEntry>(db, userId, 'receive_entries_$activeShopId', 'receive_entries', (e) => {
        'id': e.id, 'date': e.date.toIso8601String(), 'productName': e.productName,
        'companyName': e.companyName, 'price': e.price, 'quantity': e.quantity,
        'totalAmount': e.totalAmount, 'payment': e.payment,
        'paymentDate': e.paymentDate?.toIso8601String(), 'description': e.description,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _pushHiveNative<SalesLedgerEntry>(db, userId, 'sales_ledger_$activeShopId', 'sales_ledger', (e) => {
        'id': e.id, 'date': e.date.toIso8601String(), 'inItem': e.inItem, 'outItem': e.outItem,
        'price': e.price, 'quantity': e.quantity, 'totalAmount': e.totalAmount,
        'runningBalance': e.runningBalance, 'typeIndex': e.typeIndex, 'personName': e.personName,
        'payment': e.payment, 'paymentDate': e.paymentDate?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Map types via PendingSyncTracker & full local sync
      await _pushMap(db, userId, 'customer_ledger_$activeShopId', 'customer_ledger');
      await _pushMap(db, userId, 'receive_orders_$activeShopId', 'receive_orders');

      // Sync shop profile metadata to Firestore
      try {
        final authBox = await _getBox('auth');
        final rawShops = authBox.get('shops_list');
        if (rawShops is List && rawShops.isNotEmpty) {
          await db.collection('users').doc(userId).collection('profile').doc('shops').set({
            'shops': rawShops,
            'activeShopId': authBox.get('active_shop_id', defaultValue: '1'),
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
      } catch (err) {
        debugPrint('[SYNC PROFILE PUSH] $err');
      }

      // ============================================
      // 2. PULL: ALL CLOUD DATA BACK TO LOCAL HIVE
      // ============================================
      await _pullData<ProductModel>(
        db: db, userId: userId, collection: 'products', boxName: 'products_$activeShopId',
        fromMap: (map) => ProductModel.fromMap(map),
        getUpdatedAt: (item) => item.updatedAt,
      );

      await _pullData<CustomerModel>(
        db: db, userId: userId, collection: 'customers', boxName: 'customers_$activeShopId',
        fromMap: (map) => CustomerModel.fromMap(map),
        getUpdatedAt: (item) => item.updatedAt,
      );

      await _pullData<SaleModel>(
        db: db, userId: userId, collection: 'sales', boxName: 'sales_$activeShopId',
        fromMap: (map) => SaleModel.fromMap(map),
        getUpdatedAt: (item) => item.saleDate,
      );

      await _pullData<DebtModel>(
        db: db, userId: userId, collection: 'debts', boxName: 'debts_$activeShopId',
        fromMap: (map) => DebtModel.fromMap(map),
        getUpdatedAt: (item) => item.updatedAt,
      );

      await _pullData<CustomerModel>(
        db: db, userId: userId, collection: 'shop_customers', boxName: 'shop_customers_$activeShopId',
        fromMap: (map) => CustomerModel.fromMap(map),
        getUpdatedAt: (item) => item.updatedAt,
      );

      await _pullHiveNative<LedgerEntry>(db, userId, 'ledger_entries', 'ledger_entries_$activeShopId', (map) {
        return LedgerEntry(
          id: map['id']?.toString() ?? '',
          customerId: map['customerId']?.toString() ?? '',
          date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
          inItem: map['inItem'] as String?,
          outItem: map['outItem'] as String?,
          price: (map['price'] as num?)?.toDouble(),
          quantity: (map['quantity'] as num?)?.toInt(),
          totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
          runningBalance: (map['runningBalance'] as num?)?.toDouble() ?? 0.0,
          typeIndex: (map['typeIndex'] as num?)?.toInt() ?? 1,
        );
      });

      await _pullHiveNative<LedgerEntry>(db, userId, 'shop_ledger_entries', 'shop_ledger_entries_$activeShopId', (map) {
        return LedgerEntry(
          id: map['id']?.toString() ?? '',
          customerId: map['customerId']?.toString() ?? '',
          date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
          inItem: map['inItem'] as String?,
          outItem: map['outItem'] as String?,
          price: (map['price'] as num?)?.toDouble(),
          quantity: (map['quantity'] as num?)?.toInt(),
          totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
          runningBalance: (map['runningBalance'] as num?)?.toDouble() ?? 0.0,
          typeIndex: (map['typeIndex'] as num?)?.toInt() ?? 1,
        );
      });

      await _pullHiveNative<ReceiveEntry>(db, userId, 'receive_entries', 'receive_entries_$activeShopId', (map) {
        return ReceiveEntry(
          id: map['id']?.toString() ?? '',
          date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
          productName: map['productName'] as String? ?? '',
          companyName: map['companyName'] as String? ?? '',
          price: (map['price'] as num?)?.toDouble() ?? 0.0,
          quantity: (map['quantity'] as num?)?.toInt() ?? 0,
          totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
          payment: (map['payment'] as num?)?.toDouble(),
          paymentDate: map['paymentDate'] != null ? DateTime.tryParse(map['paymentDate'].toString()) : null,
          description: map['description'] as String?,
        );
      });

      await _pullHiveNative<SalesLedgerEntry>(db, userId, 'sales_ledger', 'sales_ledger_$activeShopId', (map) {
        return SalesLedgerEntry(
          id: map['id']?.toString() ?? '',
          date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
          inItem: map['inItem'] as String?,
          outItem: map['outItem'] as String?,
          price: (map['price'] as num?)?.toDouble(),
          quantity: (map['quantity'] as num?)?.toInt(),
          totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
          runningBalance: (map['runningBalance'] as num?)?.toDouble() ?? 0.0,
          typeIndex: (map['typeIndex'] as num?)?.toInt() ?? 1,
          personName: map['personName'] as String?,
          payment: (map['payment'] as num?)?.toDouble() ?? 0.0,
          paymentDate: map['paymentDate'] != null ? DateTime.tryParse(map['paymentDate'].toString()) : null,
        );
      });

      await _pullMapType(db, userId, 'customer_ledger', 'customer_ledger_$activeShopId', (map) {
        return CustomerLedgerEntryModel.fromMap(map).toMap();
      });

      await _pullMapType(db, userId, 'receive_orders', 'receive_orders_$activeShopId', (map) {
        return ReceiveOrderModel.fromMap(map).toMap();
      });

      // Pull shop profile metadata
      try {
        final profileDoc = await db.collection('users').doc(userId).collection('profile').doc('shops').get();
        if (profileDoc.exists) {
          final profileData = profileDoc.data();
          if (profileData != null && profileData['shops'] != null) {
            final remoteShops = profileData['shops'] as List<dynamic>;
            final authBox = await _getBox('auth');
            final localShops = authBox.get('shops_list') as List<dynamic>?;
            if (localShops == null || localShops.isEmpty) {
              await authBox.put('shops_list', remoteShops);
            }
          }
        }
      } catch (err) {
        debugPrint('[SYNC PROFILE PULL] $err');
      }

      debugPrint('[SYNC] All data synchronized successfully.');
      _setStatus(SyncStatus.synced);
    } catch (e, stack) {
      debugPrint('[SYNC FATAL ERROR] $e\n$stack');
      _setStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushDeletions(FirebaseFirestore db, String userId, String boxName, String collection) async {
    final deleteIds = PendingSyncTracker.getPendingDeleteIds(boxName);
    for (final id in deleteIds) {
      try {
        await db.collection('users').doc(userId).collection(collection).doc(id).delete();
        PendingSyncTracker.markDeleteSynced(boxName, id);
      } catch (err) {
        debugPrint('[SYNC DELETE ERROR] Failed deleting $collection doc $id: $err');
      }
    }
  }

  Future<void> _pushHiveNative<T>(
    FirebaseFirestore db,
    String userId,
    String boxName,
    String collection,
    Map<String, dynamic> Function(T) toMap,
  ) async {
    await _pushDeletions(db, userId, boxName, collection);

    final box = await _getBox<T>(boxName);
    final pendingIds = PendingSyncTracker.getPendingIds(boxName);

    // 1. Push explicitly pending IDs
    for (final id in pendingIds) {
      try {
        final item = box.get(id);
        if (item != null) {
          await db.collection('users').doc(userId).collection(collection).doc(id)
              .set(toMap(item), SetOptions(merge: true));
        } else {
          await db.collection('users').doc(userId).collection(collection).doc(id).delete();
        }
        PendingSyncTracker.markSynced(boxName, id);
      } catch (err) {
        debugPrint('[SYNC PUSH HIVE ERROR] Failed pushing pending $collection doc $id: $err');
      }
    }

    // 2. Also ensure any existing local entries are pushed to cloud
    for (final key in box.keys) {
      final id = key.toString();
      if (PendingSyncTracker.isPendingDelete(boxName, id)) continue;
      try {
        final item = box.get(key);
        if (item != null) {
          await db.collection('users').doc(userId).collection(collection).doc(id)
              .set(toMap(item), SetOptions(merge: true));
        }
      } catch (err) {
        debugPrint('[SYNC PUSH HIVE ERROR] Failed syncing existing $collection doc $id: $err');
      }
    }
  }

  Future<void> _pushMap(
    FirebaseFirestore db,
    String userId,
    String boxName,
    String collection,
  ) async {
    await _pushDeletions(db, userId, boxName, collection);

    final box = await _getBox(boxName);
    final pendingIds = PendingSyncTracker.getPendingIds(boxName);

    // 1. Push explicitly pending IDs
    for (final id in pendingIds) {
      try {
        final itemMap = box.get(id);
        if (itemMap != null) {
          final data = Map<String, dynamic>.from(itemMap as Map);
          data['updatedAt'] ??= DateTime.now().toIso8601String();
          await db.collection('users').doc(userId).collection(collection).doc(id)
              .set(data, SetOptions(merge: true));
        } else {
          await db.collection('users').doc(userId).collection(collection).doc(id).delete();
        }
        PendingSyncTracker.markSynced(boxName, id);
      } catch (err) {
        debugPrint('[SYNC PUSH MAP ERROR] Failed pushing pending $collection doc $id: $err');
      }
    }

    // 2. Also ensure all existing local map entries are in cloud
    for (final key in box.keys) {
      final id = key.toString();
      if (PendingSyncTracker.isPendingDelete(boxName, id)) continue;
      try {
        final itemMap = box.get(key);
        if (itemMap != null) {
          final data = Map<String, dynamic>.from(itemMap as Map);
          data['updatedAt'] ??= DateTime.now().toIso8601String();
          await db.collection('users').doc(userId).collection(collection).doc(id)
              .set(data, SetOptions(merge: true));
        }
      } catch (err) {
        debugPrint('[SYNC PUSH MAP ERROR] Failed syncing existing $collection doc $id: $err');
      }
    }
  }

  Future<void> _pullData<T>({
    required FirebaseFirestore db,
    required String userId,
    required String collection,
    required String boxName,
    required T Function(Map<String, dynamic>) fromMap,
    required DateTime Function(T) getUpdatedAt,
  }) async {
    final box = await _getBox<T>(boxName);
    final snapshot = await db.collection('users').doc(userId).collection(collection).get();

    for (final doc in snapshot.docs) {
      final id = doc.id;
      if (PendingSyncTracker.isPendingDelete(boxName, id)) continue;

      try {
        final remoteData = doc.data();
        DateTime? remoteUpdatedAt;
        if (remoteData.containsKey('updatedAt') && remoteData['updatedAt'] != null) {
          remoteUpdatedAt = DateTime.tryParse(remoteData['updatedAt'].toString());
        } else if (remoteData.containsKey('saleDate') && remoteData['saleDate'] != null) {
          remoteUpdatedAt = DateTime.tryParse(remoteData['saleDate'].toString());
        } else if (remoteData.containsKey('receivedDate') && remoteData['receivedDate'] != null) {
          remoteUpdatedAt = DateTime.tryParse(remoteData['receivedDate'].toString());
        } else if (remoteData.containsKey('date') && remoteData['date'] != null) {
          remoteUpdatedAt = DateTime.tryParse(remoteData['date'].toString());
        }

        final localItem = box.get(id);
        if (localItem == null) {
          // Record doesn't exist locally: ALWAYS insert!
          final item = fromMap(remoteData);
          await box.put(id, item);
        } else {
          final localUpdatedAt = getUpdatedAt(localItem);
          if (remoteUpdatedAt != null) {
            if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
              await box.put(id, fromMap(remoteData));
            }
          }
        }
      } catch (err, st) {
        debugPrint('[SYNC PULL ERROR] Failed pulling $collection doc $id: $err\n$st');
      }
    }
  }

  Future<void> _pullHiveNative<T>(
    FirebaseFirestore db,
    String userId,
    String collection,
    String boxName,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final box = await _getBox<T>(boxName);
    final snapshot = await db.collection('users').doc(userId).collection(collection).get();

    for (final doc in snapshot.docs) {
      final id = doc.id;
      if (PendingSyncTracker.isPendingDelete(boxName, id)) continue;

      try {
        final remoteData = doc.data();
        final isPending = PendingSyncTracker.getPendingIds(boxName).contains(id);

        if (box.get(id) == null || !isPending) {
          await box.put(id, fromMap(remoteData));
        }
      } catch (err, st) {
        debugPrint('[SYNC PULL HIVE ERROR] Failed pulling $collection doc $id: $err\n$st');
      }
    }
  }

  Future<void> _pullMapType(
    FirebaseFirestore db,
    String userId,
    String collection,
    String boxName,
    Map<String, dynamic> Function(Map<String, dynamic>) fromMap,
  ) async {
    final box = await _getBox(boxName);
    final snapshot = await db.collection('users').doc(userId).collection(collection).get();

    for (final doc in snapshot.docs) {
      final id = doc.id;
      if (PendingSyncTracker.isPendingDelete(boxName, id)) continue;

      try {
        final remoteData = doc.data();
        DateTime? remoteUpdatedAt;
        if (remoteData.containsKey('updatedAt') && remoteData['updatedAt'] != null) {
          remoteUpdatedAt = DateTime.tryParse(remoteData['updatedAt'].toString());
        } else if (remoteData.containsKey('receivedDate') && remoteData['receivedDate'] != null) {
          remoteUpdatedAt = DateTime.tryParse(remoteData['receivedDate'].toString());
        } else if (remoteData.containsKey('date') && remoteData['date'] != null) {
          remoteUpdatedAt = DateTime.tryParse(remoteData['date'].toString());
        }

        final localItemMap = box.get(id);
        if (localItemMap == null) {
          await box.put(id, fromMap(remoteData));
        } else {
          final localData = Map<String, dynamic>.from(localItemMap as Map);
          final localUpdatedAtStr = localData['updatedAt'] ?? localData['receivedDate'] ?? localData['date'];
          DateTime? localUpdatedAt;
          if (localUpdatedAtStr != null) {
            localUpdatedAt = DateTime.tryParse(localUpdatedAtStr.toString());
          }

          if (remoteUpdatedAt != null && localUpdatedAt != null) {
            if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
              await box.put(id, fromMap(remoteData));
            }
          } else {
            await box.put(id, fromMap(remoteData));
          }
        }
      } catch (err, st) {
        debugPrint('[SYNC PULL MAP ERROR] Failed pulling map $collection doc $id: $err\n$st');
      }
    }
  }

  Future<bool> hasPendingSync() async {
    if (PendingSyncTracker.hasPending()) return true;

    final products = await _productDS.getUnsyncedProducts();
    if (products.isNotEmpty) return true;
    final customers = await _customerDS.getUnsyncedCustomers();
    if (customers.isNotEmpty) return true;
    final sales = await _saleDS.getUnsyncedSales();
    if (sales.isNotEmpty) return true;
    final debts = await _debtDS.getUnsyncedDebts();
    if (debts.isNotEmpty) return true;
    final shopCustomers = await _shopCustomerDS.getUnsyncedCustomers();
    return shopCustomers.isNotEmpty;
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }
}
