import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/payment.dart';
import '../../../../core/error/result.dart';
import '../../../providers/repository_providers.dart';
import '../../invoices/controllers/invoice_list_controller.dart';

final paymentListProvider = FutureProvider.family<List<Payment>, String>((ref, invoiceId) async {
  final repo = ref.read(paymentRepositoryProvider);
  final result = await repo.getPaymentsForInvoice(invoiceId);
  
  if (result is Success<List<Payment>>) {
    return result.value;
  } else {
    throw Exception((result as Failure).failure.message);
  }
});

class PaymentDeleter {
  static Future<void> delete(WidgetRef ref, String paymentId, String invoiceId, String clientId) async {
    final repo = ref.read(paymentRepositoryProvider);
    final result = await repo.delete(paymentId);

    if (result is Success) {
      ref.invalidate(paymentListProvider(invoiceId));
      ref.invalidate(clientInvoiceListProvider(clientId));
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }

  static Future<void> deleteAttachment(WidgetRef ref, Payment payment, String attachmentId, String invoiceId, String clientId) async {
    final repo = ref.read(paymentRepositoryProvider);
    final result = await repo.update(payment, deletedAttachmentIds: [attachmentId]);

    if (result is Success) {
      ref.invalidate(paymentListProvider(invoiceId));
      ref.invalidate(clientInvoiceListProvider(clientId));
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }
}
