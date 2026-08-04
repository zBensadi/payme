import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/database_provider.dart';
import '../core/error/result.dart';
import '../core/error/failures.dart';
import '../domain/repositories/client_repository.dart';
import '../domain/repositories/invoice_repository.dart';
import '../presentation/providers/repository_providers.dart';

final clientDeletionServiceProvider = Provider<ClientDeletionService>((ref) {
  final dbService = ref.watch(databaseProvider);
  final clientRepo = ref.watch(clientRepositoryProvider);
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);

  return ClientDeletionService(dbService, clientRepo, invoiceRepo);
});

class ClientDeletionService {
  final dynamic _dbService; // DatabaseService
  final ClientRepository _clientRepository;
  final InvoiceRepository _invoiceRepository;

  ClientDeletionService(
    this._dbService,
    this._clientRepository,
    this._invoiceRepository,
  );

  /// Orchestrates the deletion of a client.
  /// If [transferToClientId] is provided, invoices are transferred before deletion.
  /// Otherwise, all invoices (and cascaded payments/attachments) are deleted.
  Future<Result<void>> deleteClientWithInvoices(String clientId, {String? transferToClientId}) async {
    try {
      await _dbService.runInTransaction((Transaction txn) async {
        if (transferToClientId != null && transferToClientId.isNotEmpty) {
          // 1. Transfer invoices
          final transferResult = await _invoiceRepository.transferInvoicesToClient(clientId, transferToClientId, txn: txn);
          if (transferResult is Failure) {
            throw Exception(transferResult.failure.message);
          }
        } else {
          // 1. Hard delete all invoices for this client
          final deleteResult = await _invoiceRepository.deleteAllForClient(clientId, txn: txn);
          if (deleteResult is Failure) {
            throw Exception(deleteResult.failure.message);
          }
        }

        // 2. Soft delete the client
        final clientResult = await _clientRepository.softDelete(clientId, txn: txn);
        if (clientResult is Failure) {
          throw Exception(clientResult.failure.message);
        }
      });

      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete client: $e'));
    }
  }
}
