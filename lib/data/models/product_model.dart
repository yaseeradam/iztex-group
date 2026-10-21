import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final String? category;

  @HiveField(5)
  final String? barcode;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final bool isSynced;

  @HiveField(8)
  final String? imagePath;

  @HiveField(9)
  final double costPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice = 0.0,
    required this.quantity,
    this.category,
    this.barcode,
    required this.updatedAt,
    this.isSynced = false,
    this.imagePath,
  });

  factory ProductModel.fromEntity(Product product) => ProductModel(
        id: product.id,
        name: product.name,
        price: product.price,
        costPrice: product.costPrice,
        quantity: product.quantity,
        category: product.category,
        barcode: product.barcode,
        updatedAt: product.updatedAt,
        isSynced: product.isSynced,
        imagePath: product.imagePath,
      );

  Product toEntity() => Product(
        id: id,
        name: name,
        price: price,
        costPrice: costPrice,
        quantity: quantity,
        category: category,
        barcode: barcode,
        updatedAt: updatedAt,
        isSynced: isSynced,
        imagePath: imagePath,
      );

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];
    final price = (rawPrice is num)
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final rawCostPrice = map['costPrice'];
    final costPrice = (rawCostPrice is num)
        ? rawCostPrice.toDouble()
        : double.tryParse(rawCostPrice?.toString() ?? '') ?? 0.0;

    final rawQuantity = map['quantity'];
    final quantity = (rawQuantity is num)
        ? rawQuantity.toInt()
        : int.tryParse(rawQuantity?.toString() ?? '') ?? 0;

    return ProductModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: price,
      costPrice: costPrice,
      quantity: quantity,
      category: map['category']?.toString(),
      barcode: map['barcode']?.toString(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      isSynced: true,
      imagePath: map['imagePath']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'costPrice': costPrice,
        'quantity': quantity,
        'category': category,
        'barcode': barcode,
        'updatedAt': updatedAt.toIso8601String(),
        'imagePath': imagePath,
      };
}
