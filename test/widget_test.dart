import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/app.dart';
import 'package:payme/presentation/features/dashboard/screens/placeholder_home_screen.dart';

void main() {
  testWidgets('App builds and shows placeholder screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PayMeApp(),
      ),
    );

    // Verify that the PlaceholderHomeScreen renders.
    expect(find.byType(PlaceholderHomeScreen), findsOneWidget);
    
    // Verify that 'PayMe' text is found.
    expect(find.text('PayMe'), findsWidgets);
  });
}
