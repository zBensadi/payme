import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/events/repository_event.dart';
import '../../../../core/error/result.dart';
import '../../../providers/active_year_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/sync_signal_provider.dart';
import '../../../utils/riverpod_invalidation_helper.dart';
import '../models/dashboard_state.dart';
import '../../../../domain/entities/invoice.dart';

final dashboardControllerProvider = FutureProvider<DashboardState>((ref) async {
  // 1. Get Active Year
  final activeYear = await ref.watch(activeYearProvider.future);
  if (activeYear == null) {
    return const DashboardNoYear();
  }

  // Watch sync signal for local mutations
  ref.watch(syncSignalProvider);

  // 2. Get all visible clients to count them
  final clientRepo = ref.watch(clientRepositoryProvider);
  ref.invalidateOnRepositoryChange(clientRepo, targetEvents: const [
    RepositoryEventType.remoteSynchronization,
    RepositoryEventType.conflictResolved,
    RepositoryEventType.bulkImport,
  ]);
  
  final clientsResult = await clientRepo.getAllVisible();
  int clientsCount = 0;
  if (clientsResult is Success) {
    clientsCount = (clientsResult as Success).value.length;
  }

  // 3. Get all invoices for the active year and compute totals
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  ref.invalidateOnRepositoryChange(invoiceRepo, targetEvents: const [
    RepositoryEventType.remoteSynchronization,
    RepositoryEventType.conflictResolved,
    RepositoryEventType.bulkImport,
  ]);
  
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  ref.invalidateOnRepositoryChange(paymentRepo, targetEvents: const [
    RepositoryEventType.remoteSynchronization,
    RepositoryEventType.conflictResolved,
    RepositoryEventType.bulkImport,
  ]);

  final invoicesResult = await invoiceRepo.getInvoicesForYear(activeYear.id);
  List<Invoice> invoices = [];
  if (invoicesResult is Success) {
    invoices = (invoicesResult as Success).value;
  }
  
  double totalInvoiced = 0;
  double totalPaid = 0;
  
  for (final invoice in invoices) {
    totalInvoiced += invoice.amount;
    
    // Fetch payments for this invoice
    final paymentsResult = await paymentRepo.getPaymentsForInvoice(invoice.id);
    if (paymentsResult is Success) {
      final payments = (paymentsResult as Success).value;
      for (final payment in payments) {
        totalPaid += payment.amount;
      }
    }
  }

  return DashboardData(
    activeYear: activeYear,
    clientsCount: clientsCount,
    invoicesCount: invoices.length,
    totalInvoiced: totalInvoiced,
    totalPaid: totalPaid,
    outstandingBalance: totalInvoiced - totalPaid,
  );
});

