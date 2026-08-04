import 'package:payme/domain/entities/invoice_status.dart';

class ReportFilterState {
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? clientId;
  final InvoiceStatus? status;

  const ReportFilterState({
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.clientId,
    this.status,
  });

  ReportFilterState copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId,
    InvoiceStatus? status,
    bool clearStatus = false,
  }) {
    return ReportFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      clientId: clientId ?? this.clientId,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  // To easily clear dates or client ID since copyWith normally ignores nulls
  ReportFilterState clearDates() {
    return ReportFilterState(
      searchQuery: searchQuery,
      clientId: clientId,
      status: status,
    );
  }

  ReportFilterState clearClient() {
    return ReportFilterState(
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
  }

  ReportFilterState clearStatus() {
    return ReportFilterState(
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      clientId: clientId,
    );
  }
}
