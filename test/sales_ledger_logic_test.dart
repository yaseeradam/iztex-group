import 'package:flutter_test/flutter_test.dart';
import 'package:shop_manager/presentation/sales_ledger/sales_ledger_screen.dart';

void main() {
  group('Sales Ledger Balance Calculations', () {
    test('Sale with immediate payment calculates correct running balance', () {
      final entries = [
        SalesLedgerEntry(
          id: '1',
          date: DateTime(2025, 1, 1),
          inItem: 'Fabric A',
          price: 1000,
          quantity: 2,
          totalAmount: 2000,
          typeIndex: 1, // Sale
          payment: 500,
          paymentDate: DateTime(2025, 1, 1),
        ),
      ];

      final computed = computeSalesLedgerBalances(entries);
      expect(computed.length, 1);
      expect(computed[0].runningBalance, 1500.0);
    });

    test('Sale with full payment results in zero balance', () {
      final entries = [
        SalesLedgerEntry(
          id: '1',
          date: DateTime(2025, 1, 1),
          inItem: 'Fabric A',
          price: 500,
          quantity: 2,
          totalAmount: 1000,
          typeIndex: 1,
          payment: 1000,
          paymentDate: DateTime(2025, 1, 1),
        ),
      ];

      final computed = computeSalesLedgerBalances(entries);
      expect(computed[0].runningBalance, 0.0);
    });

    test('Multiple sales and payments maintain accurate running debt and totals', () {
      final entries = [
        SalesLedgerEntry(
          id: 's1',
          date: DateTime(2025, 1, 1, 10),
          inItem: 'Lace Material',
          price: 5000,
          quantity: 1,
          totalAmount: 5000,
          typeIndex: 1,
          payment: 2000,
          paymentDate: DateTime(2025, 1, 1, 10),
        ),
        SalesLedgerEntry(
          id: 's2',
          date: DateTime(2025, 1, 2, 11),
          inItem: 'Brocade',
          price: 1500,
          quantity: 2,
          totalAmount: 3000,
          typeIndex: 1,
          payment: 0,
        ),
        SalesLedgerEntry(
          id: 'p1',
          date: DateTime(2025, 1, 3, 14),
          outItem: 'Cash Payment',
          totalAmount: 4000,
          typeIndex: 0,
        ),
      ];

      final computed = computeSalesLedgerBalances(entries);

      expect(computed[0].runningBalance, 3000.0);
      expect(computed[1].runningBalance, 6000.0);
      expect(computed[2].runningBalance, 2000.0);

      final totalIn = computed.where((e) => e.typeIndex == 1).fold<double>(0.0, (sum, e) => sum + e.totalAmount);
      final totalOut = computed.fold<double>(0.0, (sum, e) {
        if (e.typeIndex == 0) return sum + e.totalAmount;
        return sum + (e.payment ?? 0.0);
      });
      final remainingDebt = computed.last.runningBalance;

      expect(totalIn, 8000.0);
      expect(totalOut, 6000.0);
      expect(totalIn - totalOut, remainingDebt);
    });
  });
}
