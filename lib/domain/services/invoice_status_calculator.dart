import '../entities/invoice_status.dart';

class InvoiceStatusCalculator {
  InvoiceStatus calculate(double invoiceAmount, double paidAmount) {
    if (paidAmount <= 0) {
      return InvoiceStatus.unpaid;
    }
    
    if (paidAmount < invoiceAmount) {
      return InvoiceStatus.partiallyPaid;
    }
    
    if (paidAmount == invoiceAmount) {
      return InvoiceStatus.paid;
    }
    
    return InvoiceStatus.overpaid;
  }
}
