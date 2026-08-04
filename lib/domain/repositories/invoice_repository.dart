import '../../core/error/result.dart';
import '../entities/invoice.dart';

abstract class InvoiceRepository {
  Future<Result<List<Invoice>>> getInvoicesForYear(String accountingYearId);
  Future<Result<List<Invoice>>> getInvoicesForClient(String accountingYearId, String clientId);
  Future<Result<Invoice?>> getById(String id);
  Future<Result<Invoice>> create(Invoice invoice);
  Future<Result<Invoice>> update(Invoice invoice);
  Future<Result<void>> delete(String id);
  
  /// Retrieves the highest generated invoice number for a given year (from sequence table).
  Future<Result<int>> getHighestInvoiceNumber(String accountingYearId);

  /// Transfers all invoices from one client to another.
  Future<Result<void>> transferInvoicesToClient(String oldClientId, String newClientId, {Object? txn});

  /// Deletes all invoices for a client (which cascades to payments and attachments).
  Future<Result<void>> deleteAllForClient(String clientId, {Object? txn});

  /// Counts total invoices across all years for a client.
  Future<Result<int>> countAllForClient(String clientId);
}
