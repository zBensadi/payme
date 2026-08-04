import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../providers/active_year_provider.dart';
import '../../../providers/repository_providers.dart';
import '../models/dashboard_state.dart';

final dashboardControllerProvider = FutureProvider<DashboardState>((ref) async {
  // 1. Get Active Year
  final activeYear = await ref.watch(activeYearProvider.future);
  if (activeYear == null) {
    return const DashboardNoYear();
  }

  // 2. Get all visible clients to count them
  final clientRepo = ref.read(clientRepositoryProvider);
  final clientsResult = await clientRepo.getAllVisible();
  int clientsCount = 0;
  if (clientsResult is Success) {
    clientsCount = (clientsResult as Success).value.length;
  }

  // 3. Get all invoices for the active year and compute totals
  // The easiest way is to use InvoiceRepository and PaymentRepository,
  // or reuse our logic. We have `invoiceRepository.getInvoicesForYear`.
  final invoiceRepo = ref.read(invoiceRepositoryProvider);
  final paymentRepo = ref.read(paymentRepositoryProvider);

  final invoicesResult = await invoiceRepo.getInvoicesForYear(activeYear.id);
  if (invoicesResult is Failure) {
    throw Exception((invoicesResult as Failure).failure.message);
  }

  final invoices = (invoicesResult as Success).value;
  
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
