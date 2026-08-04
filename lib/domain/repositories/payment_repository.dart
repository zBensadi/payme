import '../../core/error/result.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Result<List<Payment>>> getPaymentsForInvoice(String invoiceId);
  Future<Result<List<Payment>>> getPaymentsByPeriod(String yearId, {DateTime? start, DateTime? end});
  Future<Result<Payment?>> getById(String id);
  
  /// Creates a payment and optionally copies/saves attachments
  Future<Result<Payment>> create(Payment payment, {List<String>? newAttachmentSourcePaths});
  
  /// Updates a payment and optionally adds new attachments or removes existing ones
  Future<Result<Payment>> update(Payment payment, {List<String>? newAttachmentSourcePaths, List<String>? deletedAttachmentIds});
  
  /// Deletes a payment and its associated physical files
  Future<Result<void>> delete(String id);

  /// Helper for cascading deletes from Invoice/Year level
  /// Returns a list of file paths that need to be deleted
  Future<Result<List<String>>> getAttachmentPathsForInvoice(String invoiceId);
  
  Future<Result<List<String>>> getAttachmentPathsForYear(String yearId);
}
