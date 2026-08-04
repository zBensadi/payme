import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/invoice_status.dart';
import '../models/report_filter_state.dart';

final reportFilterProvider = NotifierProvider<ReportFilterController, ReportFilterState>(ReportFilterController.new);

class ReportFilterController extends Notifier<ReportFilterState> {
  @override
  ReportFilterState build() => const ReportFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setClient(String? clientId) {
    state = state.copyWith(clientId: clientId);
  }

  void setStatus(InvoiceStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void clearFilters() {
    state = const ReportFilterState();
  }

  void clearDates() {
    state = state.clearDates();
  }

  void clearClient() {
    state = state.clearClient();
  }

  void clearStatus() {
    state = state.clearStatus();
  }
}
