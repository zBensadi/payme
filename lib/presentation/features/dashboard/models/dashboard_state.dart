import '../../../../domain/entities/accounting_year.dart';

sealed class DashboardState {
  const DashboardState();
}

class DashboardNoYear extends DashboardState {
  const DashboardNoYear();
}

class DashboardData extends DashboardState {
  final AccountingYear activeYear;
  final int clientsCount;
  final int invoicesCount;
  final double totalInvoiced;
  final double totalPaid;
  final double outstandingBalance;

  const DashboardData({
    required this.activeYear,
    required this.clientsCount,
    required this.invoicesCount,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.outstandingBalance,
  });
}
