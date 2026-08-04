import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/services/client_ledger_calculator.dart';
import '../../../providers/repository_providers.dart';
import '../../invoices/controllers/invoice_list_controller.dart';
import '../models/client_ledger_state.dart';

final clientLedgerControllerProvider = FutureProvider.family<ClientLedgerState, String>((ref, clientId) async {
  final clientRepo = ref.read(clientRepositoryProvider);
  
  // 1. Fetch Client
  final clientResult = await clientRepo.getById(clientId);
  if (clientResult is Failure) {
    throw Exception((clientResult as Failure).failure.message);
  }
  final client = (clientResult as Success<Client?>).value;
  if (client == null) {
    throw Exception('Client not found');
  }

  // 2. Fetch Invoices with Payments (reusing clientInvoiceListProvider)
  final invoiceItems = await ref.watch(clientInvoiceListProvider(clientId).future);
  
  // 3. Calculate Ledger Totals
  final calculator = ClientLedgerCalculator();
  final totals = calculator.calculate(invoiceItems);
  
  return ClientLedgerState(
    client: client,
    items: invoiceItems,
    totals: totals,
  );
});
