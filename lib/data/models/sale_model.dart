import 'package:hive/hive.dart';
import '../../domain/entities/sale.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 2)
class SaleItemModel {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final double unitPrice;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final double? costPrice;

  SaleItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.costPrice,
  });

  factory SaleItemModel.fromEntity(SaleItem item) => SaleItemModel(
        productId: item.productId,
        productName: item.productName,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        costPrice: item.costPrice,
      );

  SaleItem toEntity() => SaleItem(
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        quantity: quantity,
        costPrice: costPrice,
      );

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    final rawUnitPrice = map['unitPrice'];
    final unitPrice = (rawUnitPrice is num)
        ? rawUnitPrice.toDouble()
        : double.tryParse(rawUnitPrice?.toString() ?? '') ?? 0.0;

    final rawQty = map['quantity'];
    final quantity = (rawQty is num)
        ? rawQty.toInt()
        : int.tryParse(rawQty?.toString() ?? '') ?? 1;

    final rawCostPrice = map['costPrice'];
    final costPrice = (rawCostPrice is num)
        ? rawCostPrice.toDouble()
        : double.tryParse(rawCostPrice?.toString() ?? '');

    return SaleItemModel(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      unitPrice: unitPrice,
      quantity: quantity,
      costPrice: costPrice,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'costPrice': costPrice,
      };
}

@HiveType(typeId: 3)
class SaleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<SaleItemModel> items;

  @HiveField(2)
  final double totalAmount;

  @HiveField(3)
  final String? customerId;

  @HiveField(4)
  final String? customerName;

  @HiveField(5)
  final DateTime saleDate;

  @HiveField(6)
  final String paymentMethod;

  @HiveField(7)
  final bool isSynced;

  SaleModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    this.customerId,
    this.customerName,
    required this.saleDate,
    this.paymentMethod = 'cash',
    this.isSynced = false,
  });

  factory SaleModel.fromEntity(Sale sale) => SaleModel(
        id: sale.id,
        items: sale.items.map(SaleItemModel.fromEntity).toList(),
        totalAmount: sale.totalAmount,
        customerId: sale.customerId,
        customerName: sale.customerName,
        saleDate: sale.saleDate,
        paymentMethod: sale.paymentMethod,
        isSynced: sale.isSynced,
      );

  Sale toEntity() => Sale(
        id: id,
        items: items.map((e) => e.toEntity()).toList(),
        totalAmount: totalAmount,
        customerId: customerId,
        customerName: customerName,
        saleDate: saleDate,
        paymentMethod: paymentMethod,
        isSynced: isSynced,
      );

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    final rawTotal = map['totalAmount'];
    final totalAmount = (rawTotal is num)
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal?.toString() ?? '') ?? 0.0;

    final rawItems = map['items'];
    final itemsList = <SaleItemModel>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          itemsList.add(SaleItemModel.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    return SaleModel(
      id: map['id']?.toString() ?? '',
      items: itemsList,
      totalAmount: totalAmount,
      customerId: map['customerId']?.toString(),
      customerName: map['customerName']?.toString(),
      saleDate: DateTime.tryParse(map['saleDate']?.toString() ?? '') ??
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      paymentMethod: map['paymentMethod']?.toString() ?? 'cash',
      isSynced: true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'customerId': customerId,
        'customerName': customerName,
        'saleDate': saleDate.toIso8601String(),
        'updatedAt': saleDate.toIso8601String(),
        'paymentMethod': paymentMethod,
      };
}
