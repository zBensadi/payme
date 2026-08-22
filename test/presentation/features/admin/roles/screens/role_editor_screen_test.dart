import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/presentation/features/admin/roles/screens/role_editor_screen.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/entities/permissions.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'package:payme/presentation/features/admin/roles/controllers/role_editor_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:payme/core/constants/supported_locales.dart';
import 'package:payme/core/logging/logger_service.dart';

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

class MockRoleEditorController extends RoleEditorController {
  final RoleEditorState initialState;
  MockRoleEditorController(this.initialState);

  @override
  RoleEditorState build() {
    return initialState;
  }

  @override
  void init(String id) {
    // Do nothing, avoid overwriting the injected state
  }
}

void main() {
  testWidgets('RoleEditorScreen batch selection (Select All / Deselect All)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    
    // Mock the state to return a simple role
    final mockRole = UserRole(
      id: 'custom_role',
      name: 'Custom',
      isSystemRole: false,
      isEditable: true,
      isDeletable: true,
      priority: 1,
      permissions: [Permissions.clientsView],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roleEditorControllerProvider.overrideWith(() {
            return MockRoleEditorController(RoleEditorState(
              role: mockRole,
              isSaving: false,
              error: null,
              canManage: true,
            ));
          }),
          loggerProvider.overrideWithValue(MockLogger()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: SupportedLocales.all,
          home: Scaffold(
            body: RoleEditorScreen(roleId: 'custom_role'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Deselect All'), findsOneWidget);

    // Tap Select All
    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();

    // Verify a permission is selected (need to expand the tile first)
    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();
    
    // Check that 'client.view' (or whatever the actual permission string is) is checked.
    // The permission string is Permissions.clientsView which is 'clients.view'.
    final CheckboxListTile clientsViewCheckbox = tester.widget(find.widgetWithText(CheckboxListTile, 'clients.view'));
    expect(clientsViewCheckbox.value, isTrue);

    // B. Select All -> Deselect All -> all selectable permissions cleared
    await tester.tap(find.text('Deselect All'));
    await tester.pumpAndSettle();

    final CheckboxListTile clientsViewCheckboxAfterDeselect = tester.widget(find.widgetWithText(CheckboxListTile, 'clients.view'));
    expect(clientsViewCheckboxAfterDeselect.value, isFalse);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('RoleEditorScreen protected/system permissions remain protected', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    
    // Mock the state to return a system role
    final mockRole = UserRole(
      id: 'role-owner',
      name: 'Owner',
      isSystemRole: true,
      isEditable: false, // Owner role is not editable
      isDeletable: false,
      priority: 100,
      permissions: [Permissions.clientsView],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roleEditorControllerProvider.overrideWith(() {
            return MockRoleEditorController(RoleEditorState(
              role: mockRole,
              isSaving: false,
              error: null,
              canManage: true,
            ));
          }),
          loggerProvider.overrideWithValue(MockLogger()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: SupportedLocales.all,
          home: Scaffold(
            body: RoleEditorScreen(roleId: 'role-owner'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // C. protected/system permissions -> remain protected
    // Select All / Deselect All should NOT be visible
    expect(find.text('Select All'), findsNothing);
    expect(find.text('Deselect All'), findsNothing);

    // Expand Clients to verify checkboxes are disabled (onChanged is null)
    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();

    final CheckboxListTile clientsViewCheckbox = tester.widget(find.widgetWithText(CheckboxListTile, 'clients.view'));
    expect(clientsViewCheckbox.onChanged, isNull); // Disabled

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
