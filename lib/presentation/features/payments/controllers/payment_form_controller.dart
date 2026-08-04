import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../domain/entities/payment.dart';
import '../../../../domain/entities/payment_method.dart';
import '../../../providers/repository_providers.dart';
import 'payment_list_controller.dart';
import '../../invoices/controllers/invoice_list_controller.dart';

final paymentProvider = FutureProvider.family<Payment?, String>((ref, paymentId) async {
  if (paymentId == 'new') return null;
  final repo = ref.read(paymentRepositoryProvider);
  final result = await repo.getById(paymentId);
  if (result is Success<Payment?>) return result.value;
  throw Exception((result as Failure).failure.message);
});

final paymentFormProvider = AsyncNotifierProvider<PaymentFormController, void>(PaymentFormController.new);

class PaymentFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    required Payment? existingPayment,
    required String invoiceId,
    required String clientId,
    required DateTime date,
    required double amount,
    required PaymentMethod method,
    String? reference,
    String? notes,
    required List<String> newAttachmentPaths,
    required List<String> deletedAttachmentIds,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(paymentRepositoryProvider);
    
    try {
      if (existingPayment == null) {
        // Create
        final newPayment = Payment(
          id: IdGenerator.generateUniqueId(),
          invoiceId: invoiceId,
          date: date,
          amount: amount,
          method: method,
          reference: reference,
          notes: notes,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          isDirty: true,
        );
        
        final result = await repo.create(newPayment, newAttachmentSourcePaths: newAttachmentPaths);
        if (result is Failure) throw Exception((result as Failure).failure.message);
      } else {
        // Update
        final updatedPayment = existingPayment.copyWith(
          date: date,
          amount: amount,
          method: method,
          reference: reference,
          notes: notes,
          updatedAt: DateTime.now().toUtc(),
          isDirty: true,
        );
        
        final result = await repo.update(
          updatedPayment, 
          newAttachmentSourcePaths: newAttachmentPaths,
          deletedAttachmentIds: deletedAttachmentIds,
        );
        if (result is Failure) throw Exception((result as Failure).failure.message);
      }
      
      state = const AsyncData(null);
      // Invalidate caches
      ref.invalidate(paymentListProvider(invoiceId));
      ref.invalidate(clientInvoiceListProvider(clientId));
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}
