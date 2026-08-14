import '../../../domain/repositories/client_repository.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../domain/entities/client_visibility_context.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/permissions.dart';
import '../../../core/error/failures.dart';
import '../../../core/events/repository_change_publisher.dart';
import '../../../core/events/repository_event.dart';

class SecuredClientRepository implements ClientRepository, RepositoryChangePublisher {
  final ClientRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredClientRepository(this._inner, this._permissionService, this._currentUser);

  @override
  Stream<RepositoryEvent> watchEvents() {
    if (_inner is RepositoryChangePublisher) {
      return (_inner as RepositoryChangePublisher).watchEvents();
    }
    return const Stream.empty();
  }

  @override
  void dispose() {}

  AppFailure _unauthorized() {
    return const AuthFailure('Unauthorized access to client data.');
  }

  @override
  Future<Result<Client>> create(Client client) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsCreate)) {
      return Failure(_unauthorized());
    }

    // Populate ownership metadata
    final securedClient = client.copyWith(
      createdBy: _currentUser!.user.uid,
      updatedBy: _currentUser!.user.uid,
    );

    return await _inner.create(securedClient);
  }

  @override
  Future<Result<Client>> update(Client client) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsEdit)) {
      return Failure(_unauthorized());
    }

    // Preserve createdBy by fetching existing
    final existingResult = await _inner.getById(client.id);
    if (existingResult is! Success || (existingResult as Success).value == null) {
      return Failure(const DatabaseFailure('Client not found.'));
    }
    final existing = (existingResult as Success).value!;

    final securedClient = client.copyWith(
      createdBy: existing.createdBy, // Preserve original
      updatedBy: _currentUser!.user.uid, // Update updater
    );

    return await _inner.update(securedClient);
  }

  @override
  Future<Result<void>> softDelete(String id, {Object? txn}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsDelete)) {
      return Failure(_unauthorized());
    }
    return await _inner.softDelete(id, txn: txn);
  }

  @override
  Future<Result<void>> restore(String id) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsEdit)) {
      return Failure(_unauthorized());
    }
    return await _inner.restore(id);
  }

  @override
  Future<Result<Client>> getById(String id) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getById(id);
  }

  @override
  Future<Result<List<Client>>> getAllVisible({String? searchQuery, ClientVisibilityContext? visibilityContext}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsView)) {
      return Failure(_unauthorized());
    }
    
    // Pass the actual current user ID as the visibility context if no specific override is requested
    final actualVisibleToUserId = visibilityContext?.visibleToUserId ?? _currentUser!.user.uid;
    
    // We inject the visibility context down to the inner repository
    return await _inner.getAllVisible(
      searchQuery: searchQuery, 
      visibilityContext: ClientVisibilityContext(visibleToUserId: actualVisibleToUserId),
    );
  }

  @override
  Future<Result<List<Client>>> getAllDeleted({String? searchQuery}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getAllDeleted(searchQuery: searchQuery);
  }

  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.clientsView)) {
      return Failure(_unauthorized());
    }
    return await _inner.checkDuplicate(name, phone, excludeId: excludeId);
  }
}
