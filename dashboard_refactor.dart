import 'dart:io';

void main() {
  final file = File('lib/presentation/features/dashboard/screens/dashboard_screen.dart');
  String content = file.readAsStringSync();

  final oldRow1 = '''                Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.outstanding,
                        value: '\${NumberFormatter.formatAmount(dashboard.outstandingBalance)} \$currency',
                        icon: Icons.account_balance_wallet,
                        color: dashboard.outstandingBalance > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),''';

  final oldRow2 = '''                Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.totalInvoiced,
                        value: '\${NumberFormatter.formatAmount(dashboard.totalInvoiced)} \$currency',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.totalPaid,
                        value: '\${NumberFormatter.formatAmount(dashboard.totalPaid)} \$currency',
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),''';

  final oldRow3 = '''                Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.clients,
                        value: '\${dashboard.clientsCount}',
                        icon: Icons.people,
                        color: Colors.purple,
                        onTap: () => context.push('/clients'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.invoices,
                        value: '\${dashboard.invoicesCount}',
                        icon: Icons.receipt,
                        color: Colors.indigo,
                        onTap: () => context.push('/invoices'),
                      ),
                    ),
                  ],
                ),''';

  final newLayout = '''                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    
                    if (isNarrow) {
                      return Column(
                        children: [
                          SummaryTile(
                            title: AppLocalizations.of(context)!.outstanding,
                            value: '\${NumberFormatter.formatAmount(dashboard.outstandingBalance)} \$currency',
                            icon: Icons.account_balance_wallet,
                            color: dashboard.outstandingBalance > 0 ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.totalInvoiced,
                            value: '\${NumberFormatter.formatAmount(dashboard.totalInvoiced)} \$currency',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.totalPaid,
                            value: '\${NumberFormatter.formatAmount(dashboard.totalPaid)} \$currency',
                            icon: Icons.payments,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.clients,
                            value: '\${dashboard.clientsCount}',
                            icon: Icons.people,
                            color: Colors.purple,
                            onTap: () => context.push('/clients'),
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.invoices,
                            value: '\${dashboard.invoicesCount}',
                            icon: Icons.receipt,
                            color: Colors.indigo,
                            onTap: () => context.push('/invoices'),
                          ),
                        ],
                      );
                    }
                    
                    return Column(
                      children: [
\$oldRow1
                        const SizedBox(height: 8),
\$oldRow2
                        const SizedBox(height: 8),
\$oldRow3
                      ],
                    );
                  },
                ),''';

  final targetString = '''\$oldRow1
                const SizedBox(height: 8),
\$oldRow2
                const SizedBox(height: 8),
\$oldRow3''';

  if (content.contains(targetString)) {
    content = content.replaceFirst(targetString, newLayout);
    file.writeAsStringSync(content);
    print("Dashboard Layout Builder applied successfully.");
  } else {
    print("Target string not found in dashboard_screen.dart");
  }
}
