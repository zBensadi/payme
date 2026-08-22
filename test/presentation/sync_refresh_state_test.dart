import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/presentation/providers/sync_refresh_provider.dart';
import 'package:payme/presentation/widgets/sync_refresh_button.dart';
import 'package:payme/l10n/app_localizations.dart';

void main() {
  testWidgets('SyncRefreshButton reacts to syncRefreshStateProvider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              actions: const [SyncRefreshButton()],
            ),
          ),
        ),
      ),
    );

    // Initial state: not refreshing, should see the IconButton
    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Now update the provider state directly
    final element = tester.element(find.byType(SyncRefreshButton));
    final container = ProviderScope.containerOf(element);
    
    container.read(syncRefreshStateProvider.notifier).setRefreshing(true);
    await tester.pump(); // trigger rebuild

    // Should see spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);

    // Revert state
    container.read(syncRefreshStateProvider.notifier).setRefreshing(false);
    await tester.pump();

    // Should see button again
    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
