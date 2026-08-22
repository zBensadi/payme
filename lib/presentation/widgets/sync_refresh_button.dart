import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/sync_refresh_helper.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../providers/sync_refresh_provider.dart';

class SyncRefreshButton extends ConsumerWidget {
  const SyncRefreshButton({super.key});

  Future<void> _handleRefresh(WidgetRef ref) async {
    await SyncRefreshHelper.refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRefreshing = ref.watch(syncRefreshStateProvider);

    if (isRefreshing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: AppLocalizations.of(context)!.refresh,
      onPressed: () => _handleRefresh(ref),
    );
  }
}
