import '../presentation/features/invoices/models/invoice_list_item.dart';
import '../presentation/features/reports/controllers/reports_controller.dart';
import '../domain/entities/payment.dart';
import '../domain/repositories/client_repository.dart';
import '../domain/repositories/invoice_repository.dart';
import '../core/error/result.dart';
import '../core/utils/date_formatter.dart';

class CsvGenerationService {
  final ClientRepository _clientRepository;
  final InvoiceRepository _invoiceRepository;

  CsvGenerationService(this._clientRepository, this._invoiceRepository);
  Future<String> generateInvoicesCsv(List<InvoiceListItem> items) async {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('Invoice Number,Date,Due Date,Client Name,Amount,Paid Amount,Remaining,Status');
    
    // Rows
    for (final item in items) {
      final inv = item.invoice;
      String clientName = inv.clientId;
      final clientResult = await _clientRepository.getById(inv.clientId);
      if (clientResult is Success) {
        clientName = (clientResult as Success).value.name;
      }
      
      buffer.writeln('${inv.invoiceNumber},${DateFormatter.formatDate(inv.date)},${inv.dueDate != null ? DateFormatter.formatDate(inv.dueDate!) : ''},"$clientName",${inv.amount},${item.paidAmount},${item.remainingAmount},${item.status.name}');
    }
    
    return buffer.toString();
  }

  String generateClientBalancesCsv(List<ClientBalanceItem> items) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('Client Name,Total Invoiced,Total Paid,Outstanding Balance');
    
    // Rows
    for (final item in items) {
      final c = item.client;
      final t = item.totals;
      buffer.writeln('"${c.name}",${t.totalInvoiced},${t.totalPaid},${t.remainingBalance}');
    }
    
    return buffer.toString();
  }

  Future<String> generatePaymentsCsv(List<Payment> payments) async {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('Payment ID,Date,Invoice Number,Client Name,Method,Amount,Reference');
    
    // Rows
    for (final p in payments) {
      String invoiceNumber = p.invoiceId;
      String clientName = '';
      
      final invResult = await _invoiceRepository.getById(p.invoiceId);
      if (invResult is Success) {
        final inv = (invResult as Success).value;
        invoiceNumber = inv.invoiceNumber;
        
        final clientResult = await _clientRepository.getById(inv.clientId);
        if (clientResult is Success) {
          clientName = (clientResult as Success).value.name;
        }
      }

      // Wrap ref in quotes in case of commas
      final ref = p.reference != null ? '"${p.reference}"' : '';
      buffer.writeln('${p.id},${DateFormatter.formatDate(p.date)},"$invoiceNumber","$clientName",${p.method.name},${p.amount},$ref');
    }
    
    return buffer.toString();
  }
}
