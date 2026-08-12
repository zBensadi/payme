import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/payment_attachment.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../datasources/local/payment_local_datasource.dart';
import '../datasources/file/attachment_file_datasource.dart';

import '../../core/sync/synchronizable_repository.dart';
import '../../core/sync/sync_priority.dart';
import '../../core/sync/sync_result.dart';
import '../../core/sync/conflict_resolver.dart';
import '../../core/sync/sync_domain.dart';
import '../../core/sync/sync_trigger.dart';
import '../datasources/remote/payment_remote_datasource.dart';
import '../../../core/events/repository_event.dart';
import '../../../core/events/repository_change_publisher.dart';
import '../models/payment_model.dart';
import '../../domain/entities/client_visibility_context.dart';

class PaymentRepositoryImpl implements PaymentRepository, SynchronizableRepository, RepositoryChangePublisher {
  final PaymentLocalDataSource _localDataSource;
  final AttachmentFileDataSource _fileDataSource;
  final PaymentRemoteDataSource _remoteDataSource;
  final ConflictResolver<Payment> _conflictResolver;
  final SyncTrigger _syncTrigger;

  final _eventController = StreamController<RepositoryEvent>.broadcast();

  PaymentRepositoryImpl(
    this._localDataSource,
    this._fileDataSource,
    this._remoteDataSource,
    this._conflictResolver,
    this._syncTrigger,
  );

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;

  @override
  void dispose() {
    _eventController.close();
  }

  @override
  SyncDomain get syncDomain => SyncDomain.payments;

  @override
  SyncPriority get syncPriority => SyncPriority.level8Payments;

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice(String invoiceId, {ClientVisibilityContext? visibilityContext}) async {
    try {
      final payments = await _localDataSource.getPaymentsForInvoice(
        invoiceId,
        visibleToUserId: visibilityContext?.visibleToUserId,
      );
      return Success(payments);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load payments: $e'));
    }
  }

  @override
  Future<Result<List<Payment>>> getPaymentsByPeriod(String yearId, {DateTime? start, DateTime? end, ClientVisibilityContext? visibilityContext}) async {
    try {
      final payments = await _localDataSource.getPaymentsByPeriod(
        yearId, 
        start: start, 
        end: end,
        visibleToUserId: visibilityContext?.visibleToUserId,
      );
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
          
          newAttachments.add(attachment);
        }
      }

      final finalPayment = payment.copyWith(
        attachments: newAttachments,
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final created = await _localDataSource.create(finalPayment);
      _syncTrigger.requestSync(syncDomain);
      return Success(created);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to create payment: $e'));
    }
  }

  @override
  Future<Result<Payment>> update(Payment payment, {List<String>? newAttachmentSourcePaths, List<String>? deletedAttachmentIds}) async {
    try {
      List<PaymentAttachment> finalAttachments = payment.attachments.where((a) => !(deletedAttachmentIds?.contains(a.id) ?? false)).toList();

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

      final finalPayment = payment.copyWith(
        attachments: finalAttachments,
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final updated = await _localDataSource.update(finalPayment, deletedAttachmentIds ?? []);
      _syncTrigger.requestSync(syncDomain);
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
        for (final attachment in payment.attachments) {
          await _fileDataSource.deleteAttachment(attachment.filePath);
        }
        await _localDataSource.delete(id);
        _syncTrigger.requestSync(syncDomain);
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

  @override
  Future<SyncResult> pushChanges(String businessId) async {
    try {
      final dirtyModels = await _localDataSource.getDirtyPayments();
      if (dirtyModels.isEmpty) return const SyncResult(skipped: 0);

      final dirtyPayments = dirtyModels.map((m) => m as Payment).toList();
      
      await _remoteDataSource.pushPayments(businessId, dirtyPayments);
      
      final ids = dirtyPayments.map((p) => p.id).toList();
      await _localDataSource.updateSyncMetadata(ids, DateTime.now().toUtc());
      
      return SyncResult(uploaded: dirtyPayments.length);
    } catch (e, stack) {
      debugPrint('Payment push failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    try {
      final remotePayments = await _remoteDataSource.pullPayments(businessId, lastSyncTime);
      if (remotePayments.isEmpty) return const SyncResult(skipped: 0);

      int downloaded = 0;
      int conflicts = 0;

      for (final remotePayment in remotePayments) {
        final localModel = await _localDataSource.getById(remotePayment.id);
        
        if (localModel == null) {
          await _localDataSource.overwritePayment(PaymentModel.fromMap(PaymentModel.toMap(remotePayment)));
          downloaded++;
        } else {
          final localPayment = localModel as Payment;
          
          if (remotePayment.updatedAt.compareTo(localPayment.updatedAt) <= 0) {
            continue;
          }

          if (!localPayment.isDirty) {
            await _localDataSource.overwritePayment(PaymentModel.fromMap(PaymentModel.toMap(remotePayment)));
            downloaded++;
          } else {
            conflicts++;
            final winningPayment = _conflictResolver.resolve(
              localPayment,
              remotePayment,
            );
            
            if (winningPayment == remotePayment) {
              await _localDataSource.overwritePayment(PaymentModel.fromMap(PaymentModel.toMap(winningPayment)));
              downloaded++;
            }
          }
        }
      }

      if (conflicts > 0 || downloaded > 0) {
        _eventController.add(RepositoryEvent(
          type: conflicts > 0 ? RepositoryEventType.conflictResolved : RepositoryEventType.remoteSynchronization,
          domain: syncDomain,
          timestamp: DateTime.now().toUtc(),
          affectedRows: downloaded + conflicts,
        ));
      }

      return SyncResult(downloaded: downloaded, conflicts: conflicts);
    } catch (e, stack) {
      debugPrint('Payment pull failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }
}
