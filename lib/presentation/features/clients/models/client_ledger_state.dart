import '../../../../domain/entities/client.dart';
import '../../invoices/models/invoice_list_item.dart';
import '../../../../domain/services/client_ledger_calculator.dart';

class ClientLedgerState {
  final Client client;
  final List<InvoiceListItem> items;
  final ClientLedgerTotals totals;

  const ClientLedgerState({
    required this.client,
    required this.items,
    required this.totals,
  });
}
