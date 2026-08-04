import 'package:flutter/material.dart';
import '../../../../domain/entities/payment_method.dart';
import 'package:payme/l10n/app_localizations.dart';

class PaymentMethodBadge extends StatelessWidget {
  final PaymentMethod method;

  const PaymentMethodBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (method) {
      case PaymentMethod.cash:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.money;
        break;
      case PaymentMethod.bankTransfer:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.account_balance;
        break;
      case PaymentMethod.cheque:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.receipt;
        break;
    }
    
    String getLocalizedMethod(BuildContext context, PaymentMethod method) {
      switch (method) {
        case PaymentMethod.cash: return AppLocalizations.of(context)!.methodCash;
        case PaymentMethod.cheque: return AppLocalizations.of(context)!.methodCheque;
        case PaymentMethod.bankTransfer: return AppLocalizations.of(context)!.methodBankTransfer;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            getLocalizedMethod(context, method),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
