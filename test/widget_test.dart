import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:payme/app.dart';
import 'package:payme/presentation/features/dashboard/screens/dashboard_screen.dart';
import 'package:payme/presentation/features/dashboard/controllers/dashboard_controller.dart';
import 'package:payme/presentation/features/dashboard/models/dashboard_state.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/core/database/database_provider.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/presentation/features/auth/controllers/auth_controller.dart';

class FakeDatabaseService extends DatabaseService {
  FakeDatabaseService() : super(_FakeDatabase());
}

class _FakeDatabase implements Database {
  @override
  bool get isOpen => false;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthController extends Notifier<AuthState> implements AuthController {
  @override
  AuthState build() => AuthState.authenticated;
  
  @override
  void markAsAuthenticated() {}
  
  @override
  void logout() {}
}

void main() {
  testWidgets('App builds and shows placeholder screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(FakeDatabaseService()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          dashboardControllerProvider.overrideWith((ref) => Future.value(
            DashboardData(
              activeYear: AccountingYear(
                id: '1', name: '2026', isActive: true, createdAt: DateTime.now(),
              ),
              clientsCount: 0,
              invoicesCount: 0,
              totalInvoiced: 0,
              totalPaid: 0,
              outstandingBalance: 0,
            )
          )),
        ],
        child: const PayMeApp(),
      ),
    );

    // Verify that the DashboardScreen renders.
    expect(find.byType(DashboardScreen), findsOneWidget);
    
    // Verify that 'PayMe Control Center' text is found.
    expect(find.text('PayMe Control Center'), findsWidgets);
  });
}
