import '../../domain/entities/receive_order.dart';

/// Simple model stored as Map<String, dynamic> in a plain Hive Box.
class ReceiveOrderItemModel {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  ReceiveOrderItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  factory ReceiveOrderItemModel.fromEntity(ReceiveOrderItem item) =>
      ReceiveOrderItemModel(
        productId: item.productId,
        productName: item.productName,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
      );

  ReceiveOrderItem toEntity() => ReceiveOrderItem(
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        quantity: quantity,
      );

  factory ReceiveOrderItemModel.fromMap(Map<dynamic, dynamic> map) {
    final rawPrice = map['unitPrice'];
    final unitPrice = (rawPrice is num)
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final rawQty = map['quantity'];
    final quantity = (rawQty is num)
        ? rawQty.toInt()
        : int.tryParse(rawQty?.toString() ?? '') ?? 0;

    return ReceiveOrderItemModel(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };
}

class ReceiveOrderModel {
  final String id;
  final String supplierName;
  final List<ReceiveOrderItemModel> items;
  final double totalAmount;
  final DateTime receivedDate;
  final String? note;
  final bool isSynced;

  ReceiveOrderModel({
    required this.id,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    required this.receivedDate,
    this.note,
    this.isSynced = false,
  });

  factory ReceiveOrderModel.fromEntity(ReceiveOrder order) => ReceiveOrderModel(
        id: order.id,
        supplierName: order.supplierName,
        items: order.items.map(ReceiveOrderItemModel.fromEntity).toList(),
        totalAmount: order.totalAmount,
        receivedDate: order.receivedDate,
        note: order.note,
        isSynced: order.isSynced,
      );

  ReceiveOrder toEntity() => ReceiveOrder(
        id: id,
        supplierName: supplierName,
        items: items.map((e) => e.toEntity()).toList(),
        totalAmount: totalAmount,
        receivedDate: receivedDate,
        note: note,
        isSynced: isSynced,
      );

  factory ReceiveOrderModel.fromMap(Map<dynamic, dynamic> map) {
    final rawTotal = map['totalAmount'];
    final totalAmount = (rawTotal is num)
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal?.toString() ?? '') ?? 0.0;

    final rawItems = map['items'];
    final itemsList = <ReceiveOrderItemModel>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          itemsList.add(ReceiveOrderItemModel.fromMap(e));
        }
      }
    }

    final rawSynced = map['isSynced'];
    final isSynced = rawSynced == true || rawSynced?.toString().toLowerCase() == 'true';

    return ReceiveOrderModel(
      id: map['id']?.toString() ?? '',
      supplierName: map['supplierName']?.toString() ?? '',
      items: itemsList,
      totalAmount: totalAmount,
      receivedDate: DateTime.tryParse(map['receivedDate']?.toString() ?? '') ??
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      note: map['note']?.toString(),
      isSynced: isSynced,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'supplierName': supplierName,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'receivedDate': receivedDate.toIso8601String(),
        'updatedAt': receivedDate.toIso8601String(),
        'note': note,
        'isSynced': isSynced,
      };
}
