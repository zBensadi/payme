import 'package:flutter/widgets.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../domain/entities/invoice_status.dart';
import '../../domain/entities/payment_method.dart';

extension InvoiceStatusLocalization on InvoiceStatus {
  String localizedName(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case InvoiceStatus.paid:
        return loc.statusPaid;
      case InvoiceStatus.unpaid:
        return loc.statusUnpaid;
      case InvoiceStatus.partiallyPaid:
        return loc.statusPartiallyPaid;
      case InvoiceStatus.overpaid:
        return loc.statusOverpaid;
    }
  }
}

extension PaymentMethodLocalization on PaymentMethod {
  String localizedName(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case PaymentMethod.cash:
        return loc.methodCash;
      case PaymentMethod.cheque:
        return loc.methodCheque;
      case PaymentMethod.bankTransfer:
        return loc.methodBankTransfer;
    }
  }
}
