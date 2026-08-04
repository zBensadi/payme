import '../../../../domain/entities/invoice.dart';
import '../../../../domain/entities/invoice_status.dart';

class InvoiceListItem {
  final Invoice invoice;
  final double paidAmount;
  final double remainingAmount;
  final InvoiceStatus status;

  const InvoiceListItem({
    required this.invoice,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });
}
