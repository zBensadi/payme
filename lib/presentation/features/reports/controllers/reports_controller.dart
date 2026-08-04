import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/invoice_status.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/entities/payment.dart';
import '../../../../domain/services/client_ledger_calculator.dart';
import '../../../../domain/services/invoice_status_calculator.dart';
import '../../../providers/active_year_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../invoices/models/invoice_list_item.dart';
import 'report_filter_controller.dart';
// --- Shared Helper for Reports ---
// Fetches all InvoiceListItems for the active year across all clients.
final activeYearInvoiceItemsProvider = FutureProvider<List<InvoiceListItem>>((ref) async {
  final activeYear = await ref.watch(activeYearProvider.future);
  if (activeYear == null) throw Exception('No active accounting year.');

  final invoiceRepo = ref.read(invoiceRepositoryProvider);
  final paymentRepo = ref.read(paymentRepositoryProvider);

  final invoicesResult = await invoiceRepo.getInvoicesForYear(activeYear.id);
  if (invoicesResult is Failure) {
    throw Exception((invoicesResult as Failure).failure.message);
  }

  final invoices = (invoicesResult as Success).value;
  final List<InvoiceListItem> items = [];

  for (final invoice in invoices) {
    final paymentsResult = await paymentRepo.getPaymentsForInvoice(invoice.id);
    double paidAmount = 0;
    if (paymentsResult is Success) {
      final payments = (paymentsResult as Success).value;
      for (final p in payments) {
        paidAmount += p.amount;
      }
    }
    items.add(InvoiceListItem(
      invoice: invoice,
      paidAmount: paidAmount,
      remainingAmount: invoice.amount - paidAmount,
      status: InvoiceStatusCalculator().calculate(invoice.amount, paidAmount),
    ));
  }

  return items;
});

// --- Report 1: Outstanding Invoices ---
final outstandingInvoicesReportProvider = FutureProvider<List<InvoiceListItem>>((ref) async {
  final allItems = await ref.watch(activeYearInvoiceItemsProvider.future);
  final filters = ref.watch(reportFilterProvider);
  
  return allItems.where((item) {
    if (item.status != InvoiceStatus.unpaid && item.status != InvoiceStatus.partiallyPaid) return false;
    
    if (filters.clientId != null && item.invoice.clientId != filters.clientId) return false;
    if (filters.searchQuery.isNotEmpty && !item.invoice.invoiceNumber.toString().contains(filters.searchQuery)) return false;
    if (filters.startDate != null && item.invoice.date.isBefore(filters.startDate!)) return false;
    if (filters.endDate != null && item.invoice.date.isAfter(filters.endDate!)) return false;
    
    return true;
  }).toList();
});

// --- Report 2: Paid Invoices ---
final paidInvoicesReportProvider = FutureProvider<List<InvoiceListItem>>((ref) async {
  final allItems = await ref.watch(activeYearInvoiceItemsProvider.future);
  final filters = ref.watch(reportFilterProvider);

  return allItems.where((item) {
    if (item.status != InvoiceStatus.paid && item.status != InvoiceStatus.overpaid) return false;
    
    if (filters.clientId != null && item.invoice.clientId != filters.clientId) return false;
    if (filters.searchQuery.isNotEmpty && !item.invoice.invoiceNumber.toString().contains(filters.searchQuery)) return false;
    if (filters.startDate != null && item.invoice.date.isBefore(filters.startDate!)) return false;
    if (filters.endDate != null && item.invoice.date.isAfter(filters.endDate!)) return false;
    
    return true;
  }).toList();
});

// --- Report 3: Client Balances ---
class ClientBalanceItem {
  final Client client;
  final ClientLedgerTotals totals;

  const ClientBalanceItem({required this.client, required this.totals});
}

final clientBalancesReportProvider = FutureProvider<List<ClientBalanceItem>>((ref) async {
  final allItems = await ref.watch(activeYearInvoiceItemsProvider.future);
  final filters = ref.watch(reportFilterProvider);
  
  final clientRepo = ref.read(clientRepositoryProvider);
  
  final clientsResult = await clientRepo.getAllVisible();
  if (clientsResult is Failure) {
    throw Exception((clientsResult as Failure).failure.message);
  }
  
  final clients = (clientsResult as Success).value;
  final List<ClientBalanceItem> clientBalances = [];
  final calculator = ClientLedgerCalculator();

  for (final client in clients) {
    // Filter by client ID if provided
    if (filters.clientId != null && client.id != filters.clientId) continue;
    // Filter by search query if provided
    if (filters.searchQuery.isNotEmpty && !client.name.toLowerCase().contains(filters.searchQuery.toLowerCase())) continue;

    final clientInvoices = allItems.where((item) {
      if (item.invoice.clientId != client.id) return false;
      if (filters.startDate != null && item.invoice.date.isBefore(filters.startDate!)) return false;
      if (filters.endDate != null && item.invoice.date.isAfter(filters.endDate!)) return false;
      return true;
    }).toList();

    if (clientInvoices.isNotEmpty) {
      final totals = calculator.calculate(clientInvoices);
      clientBalances.add(ClientBalanceItem(client: client, totals: totals));
    }
  }

  return clientBalances;
});

// --- Report 4: Payments by Period ---
// We no longer need to use .family since we have a global filter provider!
final paymentsByPeriodReportProvider = FutureProvider<List<Payment>>((ref) async {
  final activeYear = await ref.watch(activeYearProvider.future);
  if (activeYear == null) throw Exception('No active accounting year.');

  final filters = ref.watch(reportFilterProvider);
  final paymentRepo = ref.read(paymentRepositoryProvider);
  
  final result = await paymentRepo.getPaymentsByPeriod(
    activeYear.id,
    start: filters.startDate,
    end: filters.endDate,
  );
  
  if (result is Failure) {
    throw Exception((result as Failure).failure.message);
  }
  
  List<Payment> payments = (result as Success).value;
  
  if (filters.clientId != null || filters.searchQuery.isNotEmpty) {
    final invoiceRepo = ref.read(invoiceRepositoryProvider);
    final allInvoices = await invoiceRepo.getInvoicesForYear(activeYear.id);
    if (allInvoices is Success<List<Invoice>>) {
      final invoices = allInvoices.value;
      payments = payments.where((p) {
        final inv = invoices.firstWhere((i) => i.id == p.invoiceId);
        if (filters.clientId != null && inv.clientId != filters.clientId) return false;
        if (filters.searchQuery.isNotEmpty && !inv.invoiceNumber.toString().contains(filters.searchQuery)) return false;
        return true;
      }).toList();
    }
  }

  return payments;
});

// --- Report 5: Invoices by Period ---
final invoicesByPeriodReportProvider = FutureProvider<List<InvoiceListItem>>((ref) async {
  final allItems = await ref.watch(activeYearInvoiceItemsProvider.future);
  final filters = ref.watch(reportFilterProvider);

  return allItems.where((item) {
    if (filters.clientId != null && item.invoice.clientId != filters.clientId) return false;
    if (filters.searchQuery.isNotEmpty && !item.invoice.invoiceNumber.toString().contains(filters.searchQuery)) return false;
    if (filters.startDate != null && item.invoice.date.isBefore(filters.startDate!)) return false;
    if (filters.endDate != null && item.invoice.date.isAfter(filters.endDate!)) return false;
    
    // Status filter - wait, we don't have status in ReportFilterController.
    // The instructions say "Support Status filter". I should add status to ReportFilterState.
    // I'll update report_filter_controller.dart to include it next.
    // For now, assume it's added.
    if (filters.status != null && item.status != filters.status) return false;

    return true;
  }).toList();
});
