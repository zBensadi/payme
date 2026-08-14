import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/security/permission_service.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/current_app_user.dart';
import 'package:payme/domain/entities/user_role.dart';

void main() {
  late PermissionService permissionService;

  setUp(() {
    permissionService = PermissionService();
  });

  group('PermissionService - canAssignRole', () {
    final ownerUser = AppUser(
      uid: 'owner1',
      email: 'owner@example.com',
      isSuperAdmin: false,
      isOwner: true,
      isActive: true,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final ownerRole = UserRole(
      id: 'role-owner',
      name: 'Owner',
      priority: 1000,
      isSystemRole: true,
      isEditable: false,
      isDeletable: false,
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final currentOwnerAppUser = CurrentAppUser(user: ownerUser, role: ownerRole);

    final adminUser = AppUser(
      uid: 'admin1',
      email: 'admin@example.com',
      isSuperAdmin: false,
      isOwner: false,
      isActive: true,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final adminRole = UserRole(
      id: 'role-admin',
      name: 'Admin',
      priority: 700,
      isSystemRole: false,
      isEditable: true,
      isDeletable: true,
      permissions: ['roles.manage'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final currentAdminAppUser = CurrentAppUser(user: adminUser, role: adminRole);

    test('1. Owner 1000 -> target 1000 = false', () {
      final targetRole1000 = ownerRole.copyWith(id: 'target', priority: 1000);
      final result = permissionService.canAssignRole(currentOwnerAppUser, targetRole1000);
      expect(result, false);
    });

    test('2. Owner 1000 -> target 1100 = false', () {
      final targetRole1100 = ownerRole.copyWith(id: 'target', priority: 1100);
      final result = permissionService.canAssignRole(currentOwnerAppUser, targetRole1100);
      expect(result, false);
    });

    test('3. Owner 1000 -> target 999 = true', () {
      final targetRole999 = ownerRole.copyWith(id: 'target', priority: 999);
      final result = permissionService.canAssignRole(currentOwnerAppUser, targetRole999);
      expect(result, true);
    });

    test('4. Null CurrentAppUser = false', () {
      final targetRole999 = ownerRole.copyWith(id: 'target', priority: 999);
      final result = permissionService.canAssignRole(null, targetRole999);
      expect(result, false);
    });

    test('5. Non-owner lower-priority role can manage a lower-priority role', () {
      final targetRole500 = ownerRole.copyWith(id: 'target', priority: 500, isEditable: true);
      final result = permissionService.canManageRole(currentAdminAppUser, targetRole500);
      expect(result, true);
    });

    test('6. Non-owner cannot assign equal priority', () {
      final targetRole700 = ownerRole.copyWith(id: 'target', priority: 700);
      final result = permissionService.canAssignRole(currentAdminAppUser, targetRole700);
      expect(result, false);
    });

    test('7. Non-owner cannot assign higher priority', () {
      final targetRole800 = ownerRole.copyWith(id: 'target', priority: 800);
      final result = permissionService.canAssignRole(currentAdminAppUser, targetRole800);
      expect(result, false);
    });

    test('8. Owner still has full business permission behavior where appropriate', () {
      // hasPermission should return true for Owner even if role doesn't have it
      expect(permissionService.hasPermission(currentOwnerAppUser, 'some.random.permission'), true);
      
      // Admin without permission
      final weakAdminRole = adminRole.copyWith(permissions: []);
      final weakAdminAppUser = CurrentAppUser(user: adminUser, role: weakAdminRole);
      expect(permissionService.hasPermission(weakAdminAppUser, 'some.random.permission'), false);
    });
  });
}
