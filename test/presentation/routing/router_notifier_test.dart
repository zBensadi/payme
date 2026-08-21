import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/current_app_user.dart';
import 'package:payme/domain/entities/permissions.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/presentation/features/auth/controllers/current_user_controller.dart';
import 'package:payme/presentation/routing/app_router.dart';

void main() {
  test('RouterNotifier reacts to CurrentAppUser permission changes', () async {
    final currentUserStreamController = StreamController<CurrentAppUser?>();
    
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => currentUserStreamController.stream),
      ],
    );

    // Keep the notifier alive
    final sub = container.listen(routerNotifierProvider, (_, _) {});
    final notifier = container.read(routerNotifierProvider);
    
    int notifyCount = 0;
    notifier.addListener(() {
      notifyCount++;
    });

    final user = AppUser(
      uid: 'u1', email: 'test@example.com', isSuperAdmin: false, isActive: true, 
      createdAt: DateTime.now(), updatedAt: DateTime.now()
    );

    final roleWithPerms = UserRole(
      id: 'r1', name: 'Admin', isSystemRole: false, priority: 999,
      permissions: [Permissions.accountingYearsView],
      createdAt: DateTime.now(), updatedAt: DateTime.now()
    );

    final roleWithoutPerms = UserRole(
      id: 'r1', name: 'Admin', isSystemRole: false, priority: 999,
      permissions: [],
      createdAt: DateTime.now(), updatedAt: DateTime.now()
    );

    // Initial state with permissions
    currentUserStreamController.add(CurrentAppUser(user: user, role: roleWithPerms));
    await Future.delayed(const Duration(milliseconds: 10));
    
    // Notification might fire for the first add because it changes from null to something
    final initialCount = notifyCount;

    // Change to NO permissions (revoked)
    currentUserStreamController.add(CurrentAppUser(user: user, role: roleWithoutPerms));
    await Future.delayed(const Duration(milliseconds: 10));

    expect(notifyCount, greaterThan(initialCount), reason: 'Should notify when permissions are revoked');
    final afterRevokeCount = notifyCount;

    // Change to same NO permissions (should NOT notify)
    final roleWithoutPermsUpdated = UserRole(
      id: 'r1', name: 'Admin', isSystemRole: false, priority: 999,
      permissions: [],
      createdAt: DateTime.now(), updatedAt: DateTime.now().add(const Duration(minutes: 1))
    );
    currentUserStreamController.add(CurrentAppUser(user: user, role: roleWithoutPermsUpdated));
    await Future.delayed(const Duration(milliseconds: 10));

    expect(notifyCount, afterRevokeCount, reason: 'Should NOT notify when permissions are identical');

    // Change to WITH permissions (granted)
    currentUserStreamController.add(CurrentAppUser(user: user, role: roleWithPerms));
    await Future.delayed(const Duration(milliseconds: 10));

    expect(notifyCount, greaterThan(afterRevokeCount), reason: 'Should notify when permissions are granted');
    
    await currentUserStreamController.close();
  });
}
