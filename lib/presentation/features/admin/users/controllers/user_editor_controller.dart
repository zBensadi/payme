import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/user_role.dart';
import '../../../../../domain/repositories/user_repository.dart';
import '../../../../../domain/repositories/role_repository.dart';
import '../../../../../core/error/result.dart';
import '../../../../providers/repository_providers.dart';
import '../../../../providers/permission_service_provider.dart';
import '../../../auth/controllers/current_user_controller.dart';
import '../../../../../core/security/permission_service.dart';
import '../../../../../domain/entities/current_app_user.dart';
import '../../../../../services/user_provisioning_service.dart';
import 'user_list_controller.dart';

class UserEditorState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final AppUser? user;
  final UserRole? currentRole;
  final List<UserRole> availableRoles;
  
  final bool canEdit;
  final bool canDelete;
  final bool isNewUser;

  const UserEditorState({
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.user,
    this.currentRole,
    this.availableRoles = const [],
    this.canEdit = false,
    this.canDelete = false,
    this.isNewUser = false,
  });

  UserEditorState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    AppUser? user,
    UserRole? currentRole,
    List<UserRole>? availableRoles,
    bool? canEdit,
    bool? canDelete,
    bool? isNewUser,
  }) {
    return UserEditorState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      user: user ?? this.user,
      currentRole: currentRole ?? this.currentRole,
      availableRoles: availableRoles ?? this.availableRoles,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}

class UserEditorController extends Notifier<UserEditorState> {
  late UserRepository _userRepository;
  late RoleRepository _roleRepository;
  late PermissionService _permissionService;
  late UserProvisioningService _provisioningService;
  CurrentAppUser? _currentUser;
  String? userId;

  @override
  UserEditorState build() {
    return const UserEditorState();
  }

  void init(String id) {
    if (state.isLoading && userId == id) return;
    userId = id;
    
    _userRepository = ref.read(userRepositoryProvider);
    _roleRepository = ref.read(roleRepositoryProvider);
    _permissionService = ref.read(permissionServiceProvider);
    _provisioningService = ref.read(userProvisioningServiceProvider);
    _currentUser = ref.read(currentUserProvider).value;

    Future.microtask(() => loadUser());
  }

  Future<void> loadUser() async {
    if (userId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    if (userId == 'new') {
      if (_currentUser == null) {
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }
      final rolesResult = await _roleRepository.getAllRoles();
      if (rolesResult is Failure) {
        state = state.copyWith(isLoading: false, error: (rolesResult as Failure).failure.message);
        return;
      }
      final roles = (rolesResult as Success<List<UserRole>>).value;
      final assignableRoles = roles.where((r) => _permissionService.canAssignRole(_currentUser, r)).toList();
      
      final emptyUser = AppUser(
        uid: '', 
        email: '',
        businessId: _currentUser!.user.businessId,
        isSuperAdmin: false,
        isActive: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      state = state.copyWith(
        isLoading: false,
        user: emptyUser,
        isNewUser: true,
        canEdit: true,
        canDelete: false,
        availableRoles: assignableRoles,
      );
      return;
    }

    final userResult = await _userRepository.getUserById(userId!);
    if (userResult is Failure) {
      state = state.copyWith(isLoading: false, error: (userResult as Failure).failure.message);
      return;
    }

    final user = (userResult as Success<AppUser?>).value;
    if (user == null) {
      state = state.copyWith(isLoading: false, error: 'User not found');
      return;
    }

    final rolesResult = await _roleRepository.getAllRoles();
    if (rolesResult is Failure) {
      state = state.copyWith(isLoading: false, error: (rolesResult as Failure).failure.message);
      return;
    }

    final roles = (rolesResult as Success<List<UserRole>>).value;
    
    UserRole? currentRole;
    if (user.roleId != null) {
      currentRole = roles.where((r) => r.id == user.roleId).firstOrNull;
    }

    bool canEdit = false;
    bool canDelete = false;

    if (currentRole != null) {
      canEdit = _permissionService.canEditUser(_currentUser, user, currentRole);
      canDelete = _permissionService.canDeleteUser(_currentUser, user, currentRole);
    } else {
      canEdit = _currentUser?.user.isOwner == true || _permissionService.hasPermission(_currentUser, 'users.edit');
      canDelete = _currentUser?.user.isOwner == true || _permissionService.hasPermission(_currentUser, 'users.delete');
    }

    final assignableRoles = roles.where((r) => _permissionService.canAssignRole(_currentUser, r)).toList();

    state = state.copyWith(
      isLoading: false,
      user: user,
      currentRole: currentRole,
      availableRoles: assignableRoles,
      canEdit: canEdit,
      canDelete: canDelete,
      isNewUser: false,
    );
  }

  Future<bool> saveNewUser({
    required String email, 
    required String displayName, 
    required String password, 
    required String roleId
  }) async {
    if (!state.isNewUser || state.user == null) return false;
    
    // Quick validation
    if (email.trim().isEmpty || password.length < 6 || roleId.isEmpty) {
      state = state.copyWith(error: 'Invalid input fields');
      return false;
    }

    // Role priority validation via SecuredRepository/Service
    final roleToAssign = state.availableRoles.where((r) => r.id == roleId).firstOrNull;
    if (roleToAssign == null || !_permissionService.canAssignRole(_currentUser, roleToAssign)) {
      state = state.copyWith(error: 'Not authorized to assign this role');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    // Duplicate local email check
    final allUsersResult = await _userRepository.getAllUsers();
    if (allUsersResult is Success<List<AppUser>>) {
      final exists = allUsersResult.value.any((u) => u.email.trim().toLowerCase() == email.trim().toLowerCase() && !u.isDeleted);
      if (exists) {
        state = state.copyWith(isSaving: false, error: 'Email already exists locally.');
        return false;
      }
    }

    final newUser = state.user!.copyWith(
      email: email.trim().toLowerCase(),
      displayName: displayName.trim(),
      roleId: roleId,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await _provisioningService.provisionUser(newUser, password);
    
    // Password exists only in memory for this function. It falls out of scope here.
    
    if (result is Success) {
      state = state.copyWith(isSaving: false);
      await ref.read(userListControllerProvider.notifier).loadData();
      return true;
    } else {
      state = state.copyWith(isSaving: false, error: (result as Failure).failure.message);
      return false;
    }
  }

  Future<bool> updateUser({required String displayName}) async {
    if (state.user == null || !state.canEdit) return false;
    if (displayName.trim().isEmpty) {
      state = state.copyWith(error: 'Display name cannot be empty');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    final updatedUser = state.user!.copyWith(
      displayName: displayName.trim(),
      isDirty: true,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await _userRepository.updateUser(updatedUser);

    if (result is Success) {
      state = state.copyWith(isSaving: false, user: updatedUser);
      await ref.read(userListControllerProvider.notifier).loadData();
      return true;
    } else {
      state = state.copyWith(isSaving: false, error: (result as Failure).failure.message);
      return false;
    }
  }

  Future<bool> changeRole(String newRoleId) async {
    if (state.user == null || !state.canEdit) return false;
    state = state.copyWith(isSaving: true, error: null);
    
    final updatedUser = state.user!.copyWith(
      roleId: newRoleId,
      isDirty: true,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await _userRepository.updateUser(updatedUser);
    
    if (result is Success) {
      await ref.read(userListControllerProvider.notifier).loadData();
      await loadUser();
      return true;
    } else {
      state = state.copyWith(isSaving: false, error: (result as Failure).failure.message);
      return false;
    }
  }

  Future<bool> toggleActive(bool isActive) async {
    if (state.user == null || !state.canEdit) return false;
    state = state.copyWith(isSaving: true, error: null);
    
    final updatedUser = state.user!.copyWith(
      isActive: isActive,
      isDirty: true,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await _userRepository.updateUser(updatedUser);
    
    if (result is Success) {
      await ref.read(userListControllerProvider.notifier).loadData();
      await loadUser();
      return true;
    } else {
      state = state.copyWith(isSaving: false, error: (result as Failure).failure.message);
      return false;
    }
  }

  Future<bool> softDelete() async {
    if (state.user == null || !state.canDelete) return false;
    state = state.copyWith(isSaving: true, error: null);
    
    final updatedUser = state.user!.copyWith(
      isDeleted: true,
      isActive: false,
      isDirty: true,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await _userRepository.updateUser(updatedUser);
    
    if (result is Success) {
      await ref.read(userListControllerProvider.notifier).loadData();
      return true;
    } else {
      state = state.copyWith(isSaving: false, error: (result as Failure).failure.message);
      return false;
    }
  }
}

final userEditorControllerProvider = NotifierProvider.autoDispose<UserEditorController, UserEditorState>(UserEditorController.new);







