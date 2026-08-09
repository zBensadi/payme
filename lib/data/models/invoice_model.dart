import '../../domain/entities/invoice.dart';

class InvoiceModel {
  final String id;
  final String accountingYearId;
  final String clientId;
  final int invoiceNumber;
  final String date;
  final String? description;
  final double amount;
  final String? dueDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? remoteId;
  final String? syncedAt;
  final int isDirty;
  final bool isDeleted;

  const InvoiceModel({
    required this.id,
    required this.accountingYearId,
    required this.clientId,
    required this.invoiceNumber,
    required this.date,
    this.description,
    required this.amount,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedAt,
    required this.isDirty,
    this.isDeleted = false,
  });

  factory InvoiceModel.fromEntity(Invoice entity) {
    return InvoiceModel(
      id: entity.id,
      accountingYearId: entity.accountingYearId,
      clientId: entity.clientId,
      invoiceNumber: entity.invoiceNumber,
      date: entity.date.toIso8601String(),
      description: entity.description,
      amount: entity.amount,
      dueDate: entity.dueDate?.toIso8601String(),
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      remoteId: entity.remoteId,
      syncedAt: entity.syncedAt?.toIso8601String(),
      isDirty: entity.isDirty ? 1 : 0,
      isDeleted: entity.isDeleted,
    );
  }

  Invoice toEntity() {
    return Invoice(
      id: id,
      accountingYearId: accountingYearId,
      clientId: clientId,
      invoiceNumber: invoiceNumber,
      date: DateTime.parse(date),
      description: description,
      amount: amount,
      dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      remoteId: remoteId,
      syncedAt: syncedAt != null ? DateTime.parse(syncedAt!) : null,
      isDirty: isDirty == 1,
      isDeleted: isDeleted,
    );
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String,
      accountingYearId: map['accounting_year_id'] as String,
      clientId: map['client_id'] as String,
      invoiceNumber: map['invoice_number'] as int,
      date: map['date'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['due_date'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      remoteId: map['remote_id'] as String?,
      syncedAt: map['synced_at'] as String?,
      isDirty: map['is_dirty'] as int,
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accounting_year_id': accountingYearId,
      'client_id': clientId,
      'invoice_number': invoiceNumber,
      'date': date,
      'description': description,
      'amount': amount,
      'due_date': dueDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'remote_id': remoteId,
      'synced_at': syncedAt,
      'is_dirty': isDirty,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}
