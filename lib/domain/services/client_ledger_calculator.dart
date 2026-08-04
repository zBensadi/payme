import '../../presentation/features/invoices/models/invoice_list_item.dart';

class ClientLedgerTotals {
  final double totalInvoiced;
  final double totalPaid;
  final double remainingBalance;
  final int invoiceCount;

  const ClientLedgerTotals({
    required this.totalInvoiced,
    required this.totalPaid,
    required this.remainingBalance,
    required this.invoiceCount,
  });
}

class ClientLedgerCalculator {
  ClientLedgerTotals calculate(List<InvoiceListItem> items) {
    double totalInvoiced = 0;
    double totalPaid = 0;
    double remainingBalance = 0;

    for (final item in items) {
      totalInvoiced += item.invoice.amount;
      totalPaid += item.paidAmount;
      remainingBalance += item.remainingAmount;
    }

    return ClientLedgerTotals(
      totalInvoiced: totalInvoiced,
      totalPaid: totalPaid,
      remainingBalance: remainingBalance,
      invoiceCount: items.length,
    );
  }
}
