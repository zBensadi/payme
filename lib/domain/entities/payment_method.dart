enum PaymentMethod {
  cash,
  cheque,
  bankTransfer;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      default:
        throw ArgumentError('Invalid payment method: $value');
    }
  }

  String toDbString() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }
}
