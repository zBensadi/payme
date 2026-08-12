import '../../../domain/entities/payment.dart';
import '../../../domain/entities/payment_method.dart';

class PaymentModel {
  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      method: PaymentMethod.fromString(map['method'] as String),
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      remoteId: map['remote_id'] as String?,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
      isDirty: (map['is_dirty'] as int) == 1,
      isDeleted: (map['is_deleted'] as int) == 1,
      attachments: [], // hydrated separately
    );
  }

  static Map<String, dynamic> toMap(Payment payment) {
    return {
      'id': payment.id,
      'invoice_id': payment.invoiceId,
      'date': payment.date.toIso8601String(),
      'amount': payment.amount,
      'method': payment.method.toDbString(),
      'reference': payment.reference,
      'notes': payment.notes,
      'created_by': payment.createdBy,
      'updated_by': payment.updatedBy,
      'created_at': payment.createdAt.toIso8601String(),
      'updated_at': payment.updatedAt.toIso8601String(),
      'remote_id': payment.remoteId,
      'synced_at': payment.syncedAt?.toIso8601String(),
      'is_dirty': payment.isDirty ? 1 : 0,
      'is_deleted': payment.isDeleted ? 1 : 0,
    };
  }
}
