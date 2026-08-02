import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:payme/app.dart';
import 'package:payme/presentation/features/dashboard/screens/placeholder_home_screen.dart';
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
        ],
        child: const PayMeApp(),
      ),
    );

    // Verify that the PlaceholderHomeScreen renders.
    expect(find.byType(PlaceholderHomeScreen), findsOneWidget);
    
    // Verify that 'PayMe' text is found.
    expect(find.text('PayMe'), findsWidgets);
  });
}
