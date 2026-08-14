import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/domain/entities/business_settings.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'package:payme/presentation/features/dashboard/screens/dashboard_screen.dart';
import 'package:payme/presentation/features/dashboard/widgets/summary_tile.dart';
import 'package:payme/presentation/features/dashboard/controllers/dashboard_controller.dart';
import 'package:payme/presentation/features/dashboard/models/dashboard_state.dart';
import 'package:payme/presentation/features/settings/controllers/settings_controller.dart';
import 'package:payme/presentation/features/auth/controllers/firebase_auth_controller.dart';
import 'package:payme/core/sync/sync_service.dart';
import 'package:payme/core/sync/sync_status.dart';
import 'package:payme/presentation/providers/sync_providers.dart';
import 'dart:async';

// Mock SyncService
class MockSyncService implements SyncService {
  @override
  bool get hasCompletedInitialSync => true;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock FirebaseAuthController
class MockFirebaseAuthController extends FirebaseAuthController {
  @override
  FirebaseAuthState build() {
    return FirebaseAuthState.unauthenticated;
  }
}

class MockSettingsController extends SettingsController {
  @override
  Future<BusinessSettings> build() async {
    return const BusinessSettings(
      id: 1,
      currencyCode: 'USD',
      languageCode: 'en',
    );
  }
}

void main() {
  Widget createWidgetUnderTest({required double width, required double height}) {
    final year = AccountingYear(id: 'y1', name: '2026', isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now());
    
    return ProviderScope(
      overrides: [
        dashboardControllerProvider.overrideWith((ref) => DashboardData(
          activeYear: year,
          clientsCount: 10,
          invoicesCount: 20,
          totalInvoiced: 5000,
          totalPaid: 2000,
          outstandingBalance: 3000,
        )),
        settingsControllerProvider.overrideWith(() => MockSettingsController()),
        firebaseAuthControllerProvider.overrideWith(() => MockFirebaseAuthController()),
        syncServiceProvider.overrideWithValue(MockSyncService()),
        syncStatusProvider.overrideWith((ref) => Stream.value(SyncStatus.idle)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const DashboardScreen(),
        ),
      ),
    );
  }

  testWidgets('Dashboard renders stacked metrics on narrow screens (<600)', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    await tester.pumpWidget(createWidgetUnderTest(width: 500, height: 1000));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    
    // We expect 5 SummaryTiles in the LayoutBuilder
    final summaryTiles = find.descendant(
      of: find.byType(LayoutBuilder),
      matching: find.byType(SummaryTile)
    );
    expect(summaryTiles, findsNWidgets(5));

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Dashboard renders 2x2 grid on wide screens (>=600)', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    await tester.pumpWidget(createWidgetUnderTest(width: 800, height: 1000));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    
    // We expect 5 SummaryTiles in the LayoutBuilder
    final summaryTiles = find.descendant(
      of: find.byType(LayoutBuilder),
      matching: find.byType(SummaryTile)
    );
    expect(summaryTiles, findsNWidgets(5));

    await tester.binding.setSurfaceSize(null);
  });
}
