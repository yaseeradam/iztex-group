import '../../domain/entities/customer_ledger_entry.dart';

/// Simple model stored as Map<String, dynamic> in a plain Hive Box.
class CustomerLedgerEntryModel {
  final String id;
  final String customerId;
  final DateTime date;
  final String? inDescription;
  final String? outDescription;
  final String? price;
  final int? quantity;
  final double totalAmount;
  final double totalBalance;
  final DateTime updatedAt;
  final bool isSynced;

  CustomerLedgerEntryModel({
    required this.id,
    required this.customerId,
    required this.date,
    this.inDescription,
    this.outDescription,
    this.price,
    this.quantity,
    required this.totalAmount,
    required this.totalBalance,
    required this.updatedAt,
    this.isSynced = false,
  });

  factory CustomerLedgerEntryModel.fromEntity(CustomerLedgerEntry e) =>
      CustomerLedgerEntryModel(
        id: e.id,
        customerId: e.customerId,
        date: e.date,
        inDescription: e.inDescription,
        outDescription: e.outDescription,
        price: e.price,
        quantity: e.quantity,
        totalAmount: e.totalAmount,
        totalBalance: e.totalBalance,
        updatedAt: e.updatedAt,
        isSynced: e.isSynced,
      );

  CustomerLedgerEntry toEntity() => CustomerLedgerEntry(
        id: id,
        customerId: customerId,
        date: date,
        inDescription: inDescription,
        outDescription: outDescription,
        price: price,
        quantity: quantity,
        totalAmount: totalAmount,
        totalBalance: totalBalance,
        updatedAt: updatedAt,
        isSynced: isSynced,
      );

  factory CustomerLedgerEntryModel.fromMap(Map<dynamic, dynamic> map) {
    final rawQty = map['quantity'];
    final quantity = (rawQty is num)
        ? rawQty.toInt()
        : int.tryParse(rawQty?.toString() ?? '');

    final rawTotal = map['totalAmount'];
    final totalAmount = (rawTotal is num)
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal?.toString() ?? '') ?? 0.0;

    final rawBalance = map['totalBalance'];
    final totalBalance = (rawBalance is num)
        ? rawBalance.toDouble()
        : double.tryParse(rawBalance?.toString() ?? '') ?? 0.0;

    final rawSynced = map['isSynced'];
    final isSynced = rawSynced == true || rawSynced?.toString().toLowerCase() == 'true';

    return CustomerLedgerEntryModel(
      id: map['id']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      inDescription: map['inDescription']?.toString(),
      outDescription: map['outDescription']?.toString(),
      price: map['price']?.toString(),
      quantity: quantity,
      totalAmount: totalAmount,
      totalBalance: totalBalance,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      isSynced: isSynced,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'date': date.toIso8601String(),
        'inDescription': inDescription,
        'outDescription': outDescription,
        'price': price,
        'quantity': quantity,
        'totalAmount': totalAmount,
        'totalBalance': totalBalance,
        'updatedAt': updatedAt.toIso8601String(),
        'isSynced': isSynced,
      };
}
