import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/presentation/features/admin/users/widgets/user_list_tile.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  Widget createTestWidget(AppUser user, UserRole role) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: UserListTile(
          user: user,
          role: role,
        ),
      ),
    );
  }

  final testUser = AppUser(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    businessId: 'biz-1',
    isSuperAdmin: false,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('UserListTile parses raw hex color without # successfully', (WidgetTester tester) async {
    final role = UserRole(
      id: 'role-1',
      name: 'Custom Role',
      color: '2196F3',
      priority: 10,
      isSystemRole: false,
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(testUser, role));
    await tester.pumpAndSettle();

    final circleAvatarFinder = find.byType(CircleAvatar);
    expect(circleAvatarFinder, findsOneWidget);

    final CircleAvatar avatar = tester.widget(circleAvatarFinder);
    expect(avatar.backgroundColor, const Color(0xFF2196F3));
  });

  testWidgets('UserListTile parses hex color with # successfully', (WidgetTester tester) async {
    final role = UserRole(
      id: 'role-2',
      name: 'Custom Role',
      color: '#4CAF50',
      priority: 10,
      isSystemRole: false,
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(testUser, role));
    await tester.pumpAndSettle();

    final circleAvatarFinder = find.byType(CircleAvatar);
    expect(circleAvatarFinder, findsOneWidget);

    final CircleAvatar avatar = tester.widget(circleAvatarFinder);
    expect(avatar.backgroundColor, const Color(0xFF4CAF50));
  });

  testWidgets('UserListTile falls back to blue on invalid color string', (WidgetTester tester) async {
    final role = UserRole(
      id: 'role-3',
      name: 'Custom Role',
      color: 'invalid_color',
      priority: 10,
      isSystemRole: false,
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(testUser, role));
    await tester.pumpAndSettle();

    final circleAvatarFinder = find.byType(CircleAvatar);
    expect(circleAvatarFinder, findsOneWidget);

    final CircleAvatar avatar = tester.widget(circleAvatarFinder);
    expect(avatar.backgroundColor, Colors.blue);
  });
}
