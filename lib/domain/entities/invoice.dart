class Invoice {
  final String id;
  final String accountingYearId;
  final String clientId;
  final int invoiceNumber;
  final DateTime date;
  final String? description;
  final double amount;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? remoteId;
  final DateTime? syncedAt;
  final bool isDirty;
  final bool isDeleted;

  const Invoice({
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
    this.createdBy,
    this.updatedBy,
    this.remoteId,
    this.syncedAt,
    required this.isDirty,
    this.isDeleted = false,
  });

  Invoice copyWith({
    String? id,
    String? accountingYearId,
    String? clientId,
    int? invoiceNumber,
    DateTime? date,
    String? description,
    double? amount,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? remoteId,
    DateTime? syncedAt,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return Invoice(
      id: id ?? this.id,
      accountingYearId: accountingYearId ?? this.accountingYearId,
      clientId: clientId ?? this.clientId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      remoteId: remoteId ?? this.remoteId,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
