import 'package:flutter/material.dart';
import '../../../../domain/entities/invoice_status.dart';
import 'package:payme/l10n/app_localizations.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusBadge({super.key, required this.status});

  static String getLocalizedStatus(BuildContext context, InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.unpaid:
        return AppLocalizations.of(context)!.statusUnpaid;
      case InvoiceStatus.paid:
        return AppLocalizations.of(context)!.statusPaid;
      case InvoiceStatus.partiallyPaid:
        return AppLocalizations.of(context)!.statusPartiallyPaid;
      case InvoiceStatus.overpaid:
        return AppLocalizations.of(context)!.statusOverpaid;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case InvoiceStatus.unpaid:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        text = AppLocalizations.of(context)!.statusUnpaid;
        break;
      case InvoiceStatus.partiallyPaid:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        text = AppLocalizations.of(context)!.statusPartiallyPaid;
        break;
      case InvoiceStatus.paid:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        text = AppLocalizations.of(context)!.statusPaid;
        break;
      case InvoiceStatus.overpaid:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        text = AppLocalizations.of(context)!.statusOverpaid;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
