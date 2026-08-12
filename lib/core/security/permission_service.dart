import '../../domain/entities/current_app_user.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

class PermissionService {
  /// Check if the user has a specific permission.
  /// If the user is the System Owner, they implicitly have all permissions.
  bool hasPermission(CurrentAppUser? currentUser, String permission) {
    if (currentUser == null) return false; // Fail closed
    if (currentUser.user.isOwner) return true; // Owner override
    return currentUser.role.permissions.contains(permission);
  }

  /// Check if the current user can edit the target user.
  bool canEditUser(CurrentAppUser? currentUser, AppUser targetUser, UserRole targetRole) {
    if (currentUser == null) return false;
    
    // System Owner can edit anyone
    if (currentUser.user.isOwner) return true;

    // Nobody can edit the System Owner except the System Owner themselves
    // (Wait, can Owner edit Owner? Yes, but usually self-edit is handled by the UI differently, 
    // but the system owner is allowed).
    if (targetUser.isOwner) {
      return currentUser.user.uid == targetUser.uid; 
    }

    // Must have the users.edit permission
    if (!hasPermission(currentUser, 'users.edit')) return false;

    // Cannot edit a user with a higher or equal priority role (unless it's themselves)
    if (currentUser.user.uid == targetUser.uid) return true;
    
    // Lower priority number means lower rank in this app? 
    // "Owner (1000) -> Super Admin (900) -> Admin (700)" 
    // Higher number = higher priority.
    if (currentUser.role.priority <= targetRole.priority) return false;

    return true;
  }

  /// Check if the current user can delete the target user.
  bool canDeleteUser(CurrentAppUser? currentUser, AppUser targetUser, UserRole targetRole) {
    if (currentUser == null) return false;
    
    // Cannot delete the System Owner ever
    if (targetUser.isOwner) return false;

    // Cannot delete themselves
    if (currentUser.user.uid == targetUser.uid) return false;

    if (currentUser.user.isOwner) return true;

    if (!hasPermission(currentUser, 'users.delete')) return false;

    // Cannot delete a user with a higher or equal priority role
    if (currentUser.role.priority <= targetRole.priority) return false;

    return true;
  }

  /// Check if the current user can assign a specific role.
  bool canAssignRole(CurrentAppUser? currentUser, UserRole roleToAssign) {
    if (currentUser == null) return false;

    if (currentUser.user.isOwner) return true;

    // A user cannot assign a role with priority >= their own priority
    if (currentUser.role.priority <= roleToAssign.priority) return false;

    return true;
  }

  /// Check if the current user can manage (edit/delete) a role.
  bool canManageRole(CurrentAppUser? currentUser, UserRole targetRole) {
    if (currentUser == null) return false;
    
    if (currentUser.user.isOwner) return true;

    if (!hasPermission(currentUser, 'roles.manage')) return false;

    // Cannot manage roles with priority >= their own priority
    if (currentUser.role.priority <= targetRole.priority) return false;
    
    // Cannot manage uneditable roles
    if (!targetRole.isEditable) return false;

    return true;
  }

  /// Check if the current user can manage owner-specific settings.
  bool canManageOwner(CurrentAppUser? currentUser) {
    if (currentUser == null) return false;
    return currentUser.user.isOwner;
  }
}
