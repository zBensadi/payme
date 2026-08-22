import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/app.dart';
import 'package:payme/presentation/routing/app_router.dart';
import 'package:payme/presentation/providers/locale_controller.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:payme/core/constants/supported_locales.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:payme/core/providers/shared_preferences_provider.dart';
import 'package:payme/presentation/providers/sync_providers.dart';
import 'package:payme/core/sync/sync_service.dart';
import 'package:payme/core/logging/logger_service.dart';
import 'package:payme/core/sync/sync_status.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/presentation/providers/sync_trigger_provider.dart';
import 'package:payme/core/sync/sync_trigger.dart';
import 'dart:async';

class MockSyncTrigger implements SyncTrigger {
  int requestFullSyncCallCount = 0;

  @override
  void requestFullSync() {
    requestFullSyncCallCount++;
  }

  @override
  void requestDomainSync(Set<SyncDomain> domains) {}

  @override
  void enqueue(SyncDomain domain) {}
  
  @override
  void requestSync(SyncDomain domain) {}

  @override
  Stream<SyncDomain> get syncRequested => const Stream.empty();

  @override
  void dispose() {}
}

class MockSyncService implements SyncService {
  int synchronizeDomainsCallCount = 0;

  @override
  bool hasCompletedInitialSync = true;
  
  @override
  SyncStatus get currentStatus => SyncStatus.idle;
  
  @override
  Stream<SyncStatus> get statusStream => const Stream.empty();
  
  @override
  void setBusinessId(String? businessId) {}
  
  @override
  Future<void> pause() async {}
  
  @override
  void resume() {}
  
  @override
  Future<void> synchronizeDomains(Set<SyncDomain> domains) async {
    synchronizeDomainsCallCount++;
  }
  
  @override
  void dispose() {}
}

class MockLogger implements LoggerService {
  @override
  void debug(dynamic message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void info(dynamic message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void warning(dynamic message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void error(dynamic message, {Object? error, StackTrace? stackTrace}) {}
}

void main() {
  testWidgets('PayMeApp intercepts F5 and Backspace', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                const Text('Home'),
                ElevatedButton(
                  onPressed: () => context.push('/second'),
                  child: const Text('Go Second'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/second',
          builder: (context, state) => const Scaffold(
            body: Column(
              children: [
                Text('Second'),
                TextField(key: Key('input_field')),
              ],
            ),
          ),
        ),
      ],
    );

    final mockSyncService = MockSyncService();
    final mockSyncTrigger = MockSyncTrigger();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(mockRouter),
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncServiceProvider.overrideWithValue(mockSyncService),
          syncTriggerProvider.overrideWithValue(mockSyncTrigger),
          loggerProvider.overrideWithValue(MockLogger()),
        ],
        child: const PayMeApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    // A. F5 focused normal screen -> F5 triggers the application's refresh mechanism
    expect(mockSyncTrigger.requestFullSyncCallCount, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    
    // The refresh mechanism triggers sync
    expect(mockSyncTrigger.requestFullSyncCallCount, 1);

    // Wait for SyncRefreshHelper's 15-second timeout to expire so the Timer is collected
    await tester.pump(const Duration(seconds: 15));

    // Navigate to second page
    await tester.tap(find.text('Go Second'));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);

    // Focus text field and type some text to verify normal text editing
    await tester.enterText(find.byKey(const Key('input_field')), 'Hello');
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);

    // C. Backspace with TextField focused -> navigation does NOT pop
    // Place caret at the end
    await tester.tap(find.byKey(const Key('input_field')));
    await tester.pumpAndSettle();
    
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // Should NOT pop, should still be on Second page, and text should be 'Hell'
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Hell'), findsOneWidget);

    // Unfocus
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // B. Backspace with no EditableText focused -> router pops when possible
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // Should pop back to Home
    expect(find.text('Home'), findsOneWidget);
  });
}
