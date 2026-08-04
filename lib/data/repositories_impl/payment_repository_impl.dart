import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/payment_attachment.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../datasources/local/payment_local_datasource.dart';
import '../datasources/file/attachment_file_datasource.dart';
import 'package:path/path.dart' as p;

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentLocalDataSource _localDataSource;
  final AttachmentFileDataSource _fileDataSource;

  PaymentRepositoryImpl(this._localDataSource, this._fileDataSource);

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice(String invoiceId) async {
    try {
      final payments = await _localDataSource.getPaymentsForInvoice(invoiceId);
      return Success(payments);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load payments: $e'));
    }
  }

  @override
  Future<Result<List<Payment>>> getPaymentsByPeriod(String yearId, {DateTime? start, DateTime? end}) async {
    try {
      final payments = await _localDataSource.getPaymentsByPeriod(yearId, start: start, end: end);
      return Success(payments);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load payments for period: $e'));
    }
  }

  @override
  Future<Result<Payment?>> getById(String id) async {
    try {
      final payment = await _localDataSource.getById(id);
      return Success(payment);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load payment: $e'));
    }
  }

  @override
  Future<Result<Payment>> create(Payment payment, {List<String>? newAttachmentSourcePaths}) async {
    try {
      List<PaymentAttachment> newAttachments = [...payment.attachments];

      if (newAttachmentSourcePaths != null) {
        for (final sourcePath in newAttachmentSourcePaths) {
          final originalFileName = p.basename(sourcePath);
          final extension = p.extension(sourcePath).toLowerCase().replaceAll('.', '');
          // Valid extensions: pdf, jpg, png
          final type = ['pdf', 'jpg', 'jpeg', 'png'].contains(extension) ? (extension == 'jpeg' ? 'jpg' : extension) : 'png';
          final newFileName = '${IdGenerator.generateUniqueId()}.$type';
          
          final relativePath = await _fileDataSource.saveAttachment(sourcePath, newFileName);
          
          final attachment = PaymentAttachment(
            id: IdGenerator.generateUniqueId(),
            paymentId: payment.id,
            filePath: relativePath,
            originalFileName: originalFileName,
            fileType: type,
            fileSizeBytes: 0, // In a real app we'd query the file size
            createdAt: DateTime.now().toUtc(),
          );
          
          newAttachments.add(attachment);
        }
      }

      final finalPayment = payment.copyWith(attachments: newAttachments);
      final created = await _localDataSource.create(finalPayment);
      return Success(created);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to create payment: $e'));
    }
  }

  @override
  Future<Result<Payment>> update(Payment payment, {List<String>? newAttachmentSourcePaths, List<String>? deletedAttachmentIds}) async {
    try {
      List<PaymentAttachment> finalAttachments = payment.attachments.where((a) => !(deletedAttachmentIds?.contains(a.id) ?? false)).toList();

      // Delete physical files for deleted attachments
      if (deletedAttachmentIds != null) {
        for (final deletedId in deletedAttachmentIds) {
          final toDelete = payment.attachments.firstWhere((a) => a.id == deletedId);
          await _fileDataSource.deleteAttachment(toDelete.filePath);
        }
      }

      if (newAttachmentSourcePaths != null) {
        for (final sourcePath in newAttachmentSourcePaths) {
          final originalFileName = p.basename(sourcePath);
          final extension = p.extension(sourcePath).toLowerCase().replaceAll('.', '');
          final type = ['pdf', 'jpg', 'jpeg', 'png'].contains(extension) ? (extension == 'jpeg' ? 'jpg' : extension) : 'png';
          final newFileName = '${IdGenerator.generateUniqueId()}.$type';
          
          final relativePath = await _fileDataSource.saveAttachment(sourcePath, newFileName);
          
          final attachment = PaymentAttachment(
            id: IdGenerator.generateUniqueId(),
            paymentId: payment.id,
            filePath: relativePath,
            originalFileName: originalFileName,
            fileType: type,
            fileSizeBytes: 0,
            createdAt: DateTime.now().toUtc(),
          );
          
          finalAttachments.add(attachment);
        }
      }

      final finalPayment = payment.copyWith(attachments: finalAttachments);
      final updated = await _localDataSource.update(finalPayment, deletedAttachmentIds ?? []);
      return Success(updated);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update payment: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final payment = await _localDataSource.getById(id);
      if (payment != null) {
        // Delete physical files
        for (final attachment in payment.attachments) {
          await _fileDataSource.deleteAttachment(attachment.filePath);
        }
        await _localDataSource.delete(id);
      }
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete payment: $e'));
    }
  }

  @override
  Future<Result<List<String>>> getAttachmentPathsForInvoice(String invoiceId) async {
    try {
      final paths = await _localDataSource.getAttachmentPathsForInvoice(invoiceId);
      return Success(paths);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load attachment paths: $e'));
    }
  }
  
  @override
  Future<Result<List<String>>> getAttachmentPathsForYear(String yearId) async {
    try {
      final paths = await _localDataSource.getAttachmentPathsForYear(yearId);
      return Success(paths);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load attachment paths: $e'));
    }
  }
}
