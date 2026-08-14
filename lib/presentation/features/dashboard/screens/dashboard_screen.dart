import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import '../../../../core/formatters/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../controllers/dashboard_controller.dart';
import '../../accounting_years/controllers/accounting_year_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../auth/controllers/firebase_auth_controller.dart';
import '../models/dashboard_state.dart';
import '../widgets/summary_tile.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/onboarding_checklist.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'dart:io';
import '../../../providers/sync_providers.dart';
import '../../../providers/sync_trigger_provider.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../domain/entities/permissions.dart';
import '../../../widgets/require_permission.dart';
import '../../../utils/sync_refresh_helper.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _handleCreateYear(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newAccountingYear),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.yearNameHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        await ref.read(accountingYearControllerProvider.notifier).create(newName.trim());
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildNoYearOnboarding(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.welcomeToApp(AppLocalizations.of(context)!.appTitle),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.createFirstYearDescription,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => _handleCreateYear(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.createFirstYear),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.controlCenter),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(firebaseAuthControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: state.when(
        data: (state) {
          if (state is DashboardNoYear) {
            // Wait for synchronization to finish before prompting for a new year
            // This prevents the setup screen from briefly flashing on fresh installs.
            ref.watch(syncStatusProvider); // Watch to trigger rebuilds when sync finishes
            final syncService = ref.watch(syncServiceProvider);
            if (!syncService.hasCompletedInitialSync) {
              return LoadingView(message: AppLocalizations.of(context)!.loadingDashboard);
            }
            return _buildNoYearOnboarding(context, ref);
          }
          
          final dashboard = state as DashboardData;
          final settingsState = ref.watch(settingsControllerProvider);
          final currency = settingsState.value?.currencyCode ?? '\$';
          
          return RefreshIndicator(
            onRefresh: () async {
              await SyncRefreshHelper.refresh(ref);
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                OnboardingChecklist(dashboard: dashboard),
                const SizedBox(height: 16),
                
                // Business Header
                ref.watch(settingsControllerProvider).when(
                  data: (settings) {
                    final logoFile = settings.logoPath != null ? File(settings.logoPath!) : null;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (logoFile != null && logoFile.existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                logoFile,
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.store, size: 32, color: Colors.blue),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (settings.businessName?.isNotEmpty == true) ? settings.businessName! : 'PayMe',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.event_note, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.activeYearPrefix(dashboard.activeYear.name),
                                      style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                
                const SizedBox(height: 16),
                
LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: [
                          SummaryTile(
                            title: AppLocalizations.of(context)!.outstanding,
                            value: '${NumberFormatter.formatAmount(dashboard.outstandingBalance)} $currency',
                            icon: Icons.account_balance_wallet,
                            color: dashboard.outstandingBalance > 0 ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.totalInvoiced,
                            value: '${NumberFormatter.formatAmount(dashboard.totalInvoiced)} $currency',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.totalPaid,
                            value: '${NumberFormatter.formatAmount(dashboard.totalPaid)} $currency',
                            icon: Icons.payments,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.clients,
                            value: '${dashboard.clientsCount}',
                            icon: Icons.people,
                            color: Colors.purple,
                            onTap: () => context.push('/clients'),
                          ),
                          const SizedBox(height: 8),
                          SummaryTile(
                            title: AppLocalizations.of(context)!.invoices,
                            value: '${dashboard.invoicesCount}',
                            icon: Icons.receipt,
                            color: Colors.indigo,
                            onTap: () => context.push('/invoices'),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.outstanding,
                        value: '${NumberFormatter.formatAmount(dashboard.outstandingBalance)} $currency',
                        icon: Icons.account_balance_wallet,
                        color: dashboard.outstandingBalance > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                        const SizedBox(height: 8),
                        Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.totalInvoiced,
                        value: '${NumberFormatter.formatAmount(dashboard.totalInvoiced)} $currency',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                    ),
                            const SizedBox(width: 8),
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.totalPaid,
                        value: '${NumberFormatter.formatAmount(dashboard.totalPaid)} $currency',
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                        const SizedBox(height: 8),
                        Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.clients,
                        value: '${dashboard.clientsCount}',
                        icon: Icons.people,
                        color: Colors.purple,
                        onTap: () => context.push('/clients'),
                      ),
                    ),
                            const SizedBox(width: 8),
                    Expanded(
                      child: SummaryTile(
                        title: AppLocalizations.of(context)!.invoices,
                        value: '${dashboard.invoicesCount}',
                        icon: Icons.receipt,
                        color: Colors.indigo,
                        onTap: () => context.push('/invoices'),
                      ),
                    ),
                  ],
                ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Quick Actions
                Text(
                  AppLocalizations.of(context)!.quickActions,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: 160, height: 120, child: QuickActionCard(
                      title: AppLocalizations.of(context)!.newClient,
                      icon: Icons.person_add,
                      color: Colors.teal,
                      onTap: () => context.push('/clients/new'),
                    )),
                    SizedBox(width: 160, height: 120, child: QuickActionCard(
                      title: AppLocalizations.of(context)!.clients,
                      icon: Icons.people,
                      color: Colors.purple,
                      onTap: () => context.push('/clients'),
                    )),
                    SizedBox(width: 160, height: 120, child: QuickActionCard(
                      title: AppLocalizations.of(context)!.invoices,
                      icon: Icons.receipt,
                      color: Colors.indigo,
                      onTap: () => context.push('/invoices'),
                    )),
                    SizedBox(width: 160, height: 120, child: QuickActionCard(
                      title: AppLocalizations.of(context)!.accountingYears,
                      icon: Icons.calendar_today,
                      color: Colors.deepOrange,
                      onTap: () => context.push('/accounting-years'),
                    )),
                    RequirePermission(
                      permission: Permissions.usersView,
                      child: SizedBox(width: 160, height: 120, child: QuickActionCard(
                        title: AppLocalizations.of(context)!.administration,
                        icon: Icons.admin_panel_settings,
                        color: Colors.blueGrey,
                        onTap: () => context.push('/users'),
                      )),
                    ),
                    RequirePermission(
                      permission: Permissions.rolesView,
                      child: SizedBox(width: 160, height: 120, child: QuickActionCard(
                        title: AppLocalizations.of(context)!.roles,
                        icon: Icons.security,
                        color: Colors.deepPurple,
                        onTap: () => context.push('/roles'),
                      )),
                    ),
                    SizedBox(width: 160, height: 120, child: QuickActionCard(
                      title: AppLocalizations.of(context)!.reports,
                      icon: Icons.analytics,
                      color: Colors.indigo,
                      onTap: () => context.push('/reports'),
                    )),
                    SizedBox(width: 160, height: 120, child: QuickActionCard(
                      title: AppLocalizations.of(context)!.settings,
                      icon: Icons.settings,
                      color: Colors.grey,
                      onTap: () => context.push('/settings'),
                    )),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => LoadingView(message: AppLocalizations.of(context)!.loadingDashboard),
        error: (error, _) => ErrorView(
          message: error.toString().localize(context),
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
      ),
    );
  }
}
