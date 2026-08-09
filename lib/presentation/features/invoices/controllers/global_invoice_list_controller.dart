import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/payment.dart';
import '../../../../domain/entities/invoice_status.dart';
import '../../../../domain/services/invoice_status_calculator.dart';
import '../../../providers/active_year_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../utils/riverpod_invalidation_helper.dart';
import '../../clients/controllers/client_list_controller.dart';

class GlobalInvoiceListItem {
  final Invoice invoice;
  final Client? client;
  final InvoiceStatus status;
  final double amountPaid;

  GlobalInvoiceListItem({
    required this.invoice,
    required this.client,
    required this.status,
    required this.amountPaid,
  });
}

class GlobalInvoiceFilter {
  final String searchQuery;
  final InvoiceStatus? status;

  const GlobalInvoiceFilter({
    this.searchQuery = '',
    this.status,
  });

  GlobalInvoiceFilter copyWith({
    String? searchQuery,
    InvoiceStatus? status,
    bool clearStatus = false,
  }) {
    return GlobalInvoiceFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class GlobalInvoiceFilterNotifier extends Notifier<GlobalInvoiceFilter> {
  @override
  GlobalInvoiceFilter build() => const GlobalInvoiceFilter();

  void update(GlobalInvoiceFilter Function(GlobalInvoiceFilter) cb) {
    state = cb(state);
  }
}

final globalInvoiceFilterProvider = NotifierProvider<GlobalInvoiceFilterNotifier, GlobalInvoiceFilter>(GlobalInvoiceFilterNotifier.new);

final globalInvoiceListControllerProvider = AsyncNotifierProvider<GlobalInvoiceListController, List<GlobalInvoiceListItem>>(
  GlobalInvoiceListController.new,
);

class GlobalInvoiceListController extends AsyncNotifier<List<GlobalInvoiceListItem>> {
  @override
  Future<List<GlobalInvoiceListItem>> build() async {
    final activeYearAsync = ref.watch(activeYearProvider);
    final activeYearId = activeYearAsync.maybeWhen(data: (d) => d?.id, orElse: () => null);
    if (activeYearId == null) return [];

    final filter = ref.watch(globalInvoiceFilterProvider);
    
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);
    ref.invalidateOnRepositoryChange(invoiceRepo);
    
    final invoiceResult = await invoiceRepo.getInvoicesForYear(activeYearId);
    
    if (invoiceResult is Failure) {
      throw Exception((invoiceResult as Failure<List<Invoice>>).failure.message);
    }
    
    final invoices = (invoiceResult as Success<List<Invoice>>).value;
    
    // We also need all clients to map the names
    final clients = ref.watch(clientListControllerProvider).maybeWhen(data: (d) => d, orElse: () => <Client>[]);
    final clientMap = {for (var c in clients) c.id: c};

    // Calculate status for each invoice
    final calculator = InvoiceStatusCalculator();
    
    final List<GlobalInvoiceListItem> items = [];
    
    for (final invoice in invoices) {
      final paymentsResult = await ref.watch(paymentRepositoryProvider).getPaymentsForInvoice(invoice.id);
      final payments = paymentsResult is Success ? (paymentsResult as Success<List<Payment>>).value : <Payment>[];
      final amountPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
      
      final status = calculator.calculate(invoice.amount, amountPaid);
      final client = clientMap[invoice.clientId];
      
      // Apply filters
      if (filter.status != null && filter.status != status) {
        continue;
      }
      
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final matchesNumber = invoice.invoiceNumber.toString().contains(query);
        final matchesClient = client?.name.toLowerCase().contains(query) ?? false;
        if (!matchesNumber && !matchesClient) {
          continue;
        }
      }
      
      items.add(GlobalInvoiceListItem(
        invoice: invoice,
        client: client,
        status: status,
        amountPaid: amountPaid,
      ));
    }
    
    return items;
  }
  
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
