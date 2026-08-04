import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/invoice.dart';
import 'package:payme/domain/entities/invoice_status.dart';
import 'package:payme/domain/services/client_ledger_calculator.dart';
import 'package:payme/presentation/features/invoices/models/invoice_list_item.dart';

void main() {
  group('ClientLedgerCalculator', () {
    late ClientLedgerCalculator calculator;
    
    setUp(() {
      calculator = ClientLedgerCalculator();
    });

    test('calculates correct totals for empty list', () {
      final totals = calculator.calculate([]);
      
      expect(totals.totalInvoiced, 0);
      expect(totals.totalPaid, 0);
      expect(totals.remainingBalance, 0);
      expect(totals.invoiceCount, 0);
    });

    test('calculates correct totals for multiple invoices with varying payments', () {
      final now = DateTime.now();
      
      final invoice1 = Invoice(
        id: 'inv1',
        accountingYearId: 'yr1',
        clientId: 'c1',
        invoiceNumber: 1,
        date: now,
        amount: 100.0,
        createdAt: now,
        updatedAt: now,
        isDirty: false,
      );

      final item1 = InvoiceListItem(
        invoice: invoice1,
        paidAmount: 20.0,
        remainingAmount: 80.0,
        status: InvoiceStatus.partiallyPaid,
      );

      final invoice2 = Invoice(
        id: 'inv2',
        accountingYearId: 'yr1',
        clientId: 'c1',
        invoiceNumber: 2,
        date: now,
        amount: 200.0,
        createdAt: now,
        updatedAt: now,
        isDirty: false,
      );

      final item2 = InvoiceListItem(
        invoice: invoice2,
        paidAmount: 200.0,
        remainingAmount: 0.0,
        status: InvoiceStatus.paid,
      );

      final invoice3 = Invoice(
        id: 'inv3',
        accountingYearId: 'yr1',
        clientId: 'c1',
        invoiceNumber: 3,
        date: now,
        amount: 50.0,
        createdAt: now,
        updatedAt: now,
        isDirty: false,
      );

      final item3 = InvoiceListItem(
        invoice: invoice3,
        paidAmount: 60.0, // overpaid
        remainingAmount: -10.0,
        status: InvoiceStatus.overpaid,
      );

      final totals = calculator.calculate([item1, item2, item3]);
      
      // Expected:
      // Total Invoiced: 100 + 200 + 50 = 350
      // Total Paid: 20 + 200 + 60 = 280
      // Remaining: 80 + 0 + (-10) = 70
      // Count: 3

      expect(totals.totalInvoiced, 350.0);
      expect(totals.totalPaid, 280.0);
      expect(totals.remainingBalance, 70.0);
      expect(totals.invoiceCount, 3);
    });
  });
}
