import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/sync_refresh_helper.dart';
import 'package:payme/l10n/app_localizations.dart';

class SyncRefreshButton extends ConsumerStatefulWidget {
  const SyncRefreshButton({super.key});

  @override
  ConsumerState<SyncRefreshButton> createState() => _SyncRefreshButtonState();
}

class _SyncRefreshButtonState extends ConsumerState<SyncRefreshButton> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await SyncRefreshHelper.refresh(ref);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRefreshing) {
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
      onPressed: _handleRefresh,
    );
  }
}
