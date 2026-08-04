import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/dashboard_state.dart';
import '../../settings/controllers/settings_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

class OnboardingChecklist extends ConsumerWidget {
  final DashboardData dashboard;

  const OnboardingChecklist({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final settings = settingsState.value;

    final bool hasBusinessProfile = settings != null && (settings.businessName?.isNotEmpty ?? false);
    final bool hasYear = true; // since dashboard is DashboardData
    final bool hasClient = dashboard.clientsCount > 0;
    final bool hasInvoice = dashboard.invoicesCount > 0;
    final bool hasPayment = dashboard.totalPaid > 0;

    final completedSteps = [hasBusinessProfile, hasYear, hasClient, hasInvoice, hasPayment].where((b) => b).length;
    final totalSteps = 5;

    if (completedSteps == totalSteps) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.gettingStartedProgress(completedSteps, totalSteps),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Icon(Icons.rocket_launch, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completedSteps / totalSteps,
              backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            _ChecklistItem(
              title: AppLocalizations.of(context)!.stepCompleteProfile,
              isCompleted: hasBusinessProfile,
              onTap: () => context.push('/settings'),
            ),
            _ChecklistItem(
              title: AppLocalizations.of(context)!.stepCreateYear,
              isCompleted: hasYear,
              onTap: () => context.push('/accounting-years'),
            ),
            _ChecklistItem(
              title: AppLocalizations.of(context)!.stepCreateClient,
              isCompleted: hasClient,
              onTap: () => context.push('/clients/new'),
            ),
            _ChecklistItem(
              title: AppLocalizations.of(context)!.stepCreateInvoice,
              isCompleted: hasInvoice,
              onTap: () => hasClient ? context.push('/clients') : null, // Need a client first to create an invoice easily
            ),
            _ChecklistItem(
              title: AppLocalizations.of(context)!.stepRecordPayment,
              isCompleted: hasPayment,
              onTap: () => hasInvoice ? context.push('/reports/outstanding') : null, // Go to outstanding invoices to pay
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _ChecklistItem({
    required this.title,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isCompleted ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
            ),
            if (!isCompleted && onTap != null)
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
