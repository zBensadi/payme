import 'payment_method.dart';
import 'payment_attachment.dart';

class Payment {
  final String id;
  final String invoiceId;
  final DateTime date;
  final double amount;
  final PaymentMethod method;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final DateTime? syncedAt;
  final bool isDirty;
  final bool isDeleted;
  
  // Attachments are loaded optionally
  final List<PaymentAttachment> attachments;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.date,
    required this.amount,
    required this.method,
    this.reference,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedAt,
    required this.isDirty,
    this.isDeleted = false,
    this.attachments = const [],
  });

  Payment copyWith({
    String? id,
    String? invoiceId,
    DateTime? date,
    double? amount,
    PaymentMethod? method,
    String? reference,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    DateTime? syncedAt,
    bool? isDirty,
    bool? isDeleted,
    List<PaymentAttachment>? attachments,
  }) {
    return Payment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
      attachments: attachments ?? this.attachments,
    );
  }
}
