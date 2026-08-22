import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../domain/services/invoice_number_generator.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/active_year_provider.dart';
import 'invoice_list_controller.dart';
import 'global_invoice_list_controller.dart';

final invoiceFormControllerProvider = AsyncNotifierProvider<InvoiceFormController, void>(InvoiceFormController.new);

class InvoiceFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save(Invoice invoice, String clientId) async {
    state = const AsyncLoading();
    
    final repo = ref.read(invoiceRepositoryProvider);
    final yearState = ref.read(activeYearProvider);
    final yearId = yearState.value?.id;

    if (yearId == null) {
      state = AsyncError(Exception('No active accounting year'), StackTrace.current);
      return false;
    }

    Result<Invoice> result;

    if (invoice.id.isEmpty) {
      // 1. Generate Invoice Number via Domain Service
      final generator = InvoiceNumberGenerator(repo);
      final numResult = await generator.generateNext(yearId);
      
      if (numResult is Failure) {
        state = AsyncError(Exception((numResult as Failure).failure.message), StackTrace.current);
        return false;
      }

      final newInvoiceNumber = (numResult as Success<int>).value;

      final newInvoice = invoice.copyWith(
        id: IdGenerator.generateUniqueId(),
        accountingYearId: yearId,
        clientId: clientId,
        invoiceNumber: newInvoiceNumber,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        isDirty: true,
      );
      result = await repo.create(newInvoice);
    } else {
      final updatedInvoice = invoice.copyWith(
        updatedAt: DateTime.now().toUtc(),
        isDirty: true,
      );
      result = await repo.update(updatedInvoice);
    }

    if (result is Success<Invoice>) {
      state = const AsyncData(null);
      // Invalidate the list for this client and the global list
      ref.invalidate(clientInvoiceListProvider(clientId));
      ref.invalidate(globalInvoiceListControllerProvider);
      return true;
    } else {
      state = AsyncError(Exception((result as Failure).failure.message), StackTrace.current);
      return false;
    }
  }
}
