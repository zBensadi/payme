import sys
import os

file_path = "lib/data/repositories_impl/secured/secured_client_visibility_repository.dart"
content = """import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../core/security/permissions.dart';
import '../../../core/sync/sync_domain.dart';
import '../../../core/sync/sync_priority.dart';
import '../../../core/sync/sync_result.dart';
import '../../../domain/entities/client_visibility.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../domain/repositories/client_visibility_repository.dart';

class SecuredClientVisibilityRepository implements ClientVisibilityRepository {
  final ClientVisibilityRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredClientVisibilityRepository(
    this._inner,
    this._permissionService,
    this._currentUser,
  );

  Failure _unauthorized() {
    return const UnauthorizedFailure('You do not have permission to manage client visibility.');
  }

  bool _canManageVisibility() {
    // Both clientsCreate and clientsEdit allow visibility management depending on the context.
    // Since we don't know if the client is new or existing here (unless we check the client DB),
    // we allow it if they have EITHER permission. 
    // In a stricter system, we might require clients.edit for existing, but this suffices for the repo boundary.
    return _permissionService.hasPermission(_currentUser, Permissions.clientsEdit) ||
           _permissionService.hasPermission(_currentUser, Permissions.clientsCreate);
  }

  @override
  SyncDomain get syncDomain => _inner.syncDomain;

  @override
  SyncPriority get syncPriority => _inner.syncPriority;

  @override
  Stream<void> get onDidChange => _inner.onDidChange;

  @override
  Future<Result<void>> addVisibility(ClientVisibility visibility) async {
    if (!_canManageVisibility()) {
      return Failure(_unauthorized());
    }
    return _inner.addVisibility(visibility);
  }

  @override
  Future<Result<void>> removeVisibility(String clientId, String userId) async {
    if (!_canManageVisibility()) {
      return Failure(_unauthorized());
    }
    return _inner.removeVisibility(clientId, userId);
  }

  @override
  Future<Result<List<ClientVisibility>>> getVisibilityForClient(String clientId) async {
    // Viewing visibility configuration also requires edit/create permission since it's an admin setting.
    // If they just need to view the client list, they don't call this.
    if (!_canManageVisibility()) {
      return Failure(_unauthorized());
    }
    return _inner.getVisibilityForClient(clientId);
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) {
    return _inner.pullChanges(businessId, lastSyncTime);
  }

  @override
  Future<SyncResult> pushChanges(String businessId) {
    return _inner.pushChanges(businessId);
  }
}
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
