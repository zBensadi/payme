import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/services/invoice_status_calculator.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/active_year_provider.dart';
import '../models/invoice_list_item.dart';
import 'global_invoice_list_controller.dart';

// Provides the invoices for a specific client in the active year
final clientInvoiceListProvider = FutureProvider.family<List<InvoiceListItem>, String>((ref, clientId) async {
  final yearState = ref.watch(activeYearProvider);
  final yearId = yearState.value?.id;
  if (yearId == null) return [];

  final invoiceRepo = ref.read(invoiceRepositoryProvider);
  final paymentRepo = ref.read(paymentRepositoryProvider);
  
  final result = await invoiceRepo.getInvoicesForClient(yearId, clientId);
  
  if (result is Success<List<Invoice>>) {
    final invoices = result.value;
    final List<InvoiceListItem> items = [];
    final calculator = InvoiceStatusCalculator();
    
    for (final invoice in invoices) {
      final paymentResult = await paymentRepo.getPaymentsForInvoice(invoice.id);
      double paidAmount = 0.0;
      
      if (paymentResult is Success) {
        final payments = (paymentResult as Success).value;
        for (final p in payments) {
          paidAmount += p.amount;
        }
      }
      
      final remainingAmount = invoice.amount - paidAmount;
      final status = calculator.calculate(invoice.amount, paidAmount);
      
      items.add(InvoiceListItem(
        invoice: invoice,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        status: status,
      ));
    }
    
    return items;
  } else {
    throw Exception((result as Failure).failure.message);
  }
});

class InvoiceDeleter {
  static Future<void> delete(WidgetRef ref, String invoiceId, String clientId) async {
    final repo = ref.read(invoiceRepositoryProvider);
    final result = await repo.delete(invoiceId);

    if (result is Success) {
      ref.invalidate(clientInvoiceListProvider(clientId));
      ref.invalidate(globalInvoiceListControllerProvider);
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }
}
