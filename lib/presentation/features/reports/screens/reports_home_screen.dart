import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:payme/l10n/app_localizations.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _ReportCard(
            title: AppLocalizations.of(context)!.reportOutstandingInvoices,
            subtitle: AppLocalizations.of(context)!.reportOutstandingDesc,
            icon: Icons.assignment_late,
            color: Colors.orange,
            onTap: () => context.push('/reports/outstanding'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            title: AppLocalizations.of(context)!.reportPaidInvoices,
            subtitle: AppLocalizations.of(context)!.reportPaidDesc,
            icon: Icons.assignment_turned_in,
            color: Colors.green,
            onTap: () => context.push('/reports/paid'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            title: AppLocalizations.of(context)!.reportClientBalances,
            subtitle: AppLocalizations.of(context)!.reportClientBalancesDesc,
            icon: Icons.account_balance,
            color: Colors.purple,
            onTap: () => context.push('/reports/client-balances'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            title: AppLocalizations.of(context)!.reportPaymentsByPeriod,
            subtitle: AppLocalizations.of(context)!.reportPaymentsDesc,
            icon: Icons.date_range,
            color: Colors.blue,
            onTap: () => context.push('/reports/payments'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            title: AppLocalizations.of(context)!.reportInvoicesByPeriod,
            subtitle: AppLocalizations.of(context)!.reportInvoicesByPeriodDesc,
            icon: Icons.receipt_long,
            color: Colors.indigo,
            onTap: () => context.push('/reports/invoices-by-period'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
