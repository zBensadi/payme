import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/presentation/providers/permission_service_provider.dart';
import 'package:payme/presentation/features/auth/controllers/current_user_controller.dart';
import 'role_list_controller.dart';
import 'package:uuid/uuid.dart';

final roleEditorControllerProvider = NotifierProvider<RoleEditorController, RoleEditorState>(RoleEditorController.new);

class RoleEditorState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final UserRole? role;
  final bool canManage;
  final int maxAllowedPriorityValue; // Highest numerical value they can assign (highest actual priority)

  const RoleEditorState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.role,
    this.canManage = false,
    this.maxAllowedPriorityValue = 0,
  });

  RoleEditorState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    UserRole? role,
    bool? canManage,
    int? maxAllowedPriorityValue,
  }) {
    return RoleEditorState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      role: role ?? this.role,
      canManage: canManage ?? this.canManage,
      maxAllowedPriorityValue: maxAllowedPriorityValue ?? this.maxAllowedPriorityValue,
    );
  }
}

class RoleEditorController extends Notifier<RoleEditorState> {
  String? roleId;

  @override
  RoleEditorState build() {
    return const RoleEditorState(isLoading: true);
  }

  void init(String id) {
    if (state.isLoading && roleId == id) return;
    roleId = id;
    Future.microtask(() => loadRole());
  }

  Future<void> loadRole() async {
    if (roleId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    
    final repo = ref.read(roleRepositoryProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final currentUser = ref.read(currentUserProvider).value;

    int maxAllowedPriority = currentUser != null ? currentUser.role.priority - 1 : 0;

    if (roleId == 'new') {
      final now = DateTime.now().toUtc();
      final newRole = UserRole(
        id: const Uuid().v4(),
        name: '',
        description: '',
        color: '2196F3', // Default blue
        priority: 10,
        isSystemRole: false,
        isEditable: true,
        isDeletable: true,
        permissions: const [],
        createdAt: now,
        updatedAt: now,
      );
      state = state.copyWith(
        isLoading: false,
        role: newRole,
        canManage: true,
        maxAllowedPriorityValue: maxAllowedPriority,
      );
      return;
    }

    final result = await repo.getRoleById(roleId!);

    if (result is Failure) {
      state = state.copyWith(
        isLoading: false,
        error: (result as Failure).failure.message,
      );
      return;
    }

    final role = (result as Success<UserRole?>).value;
    if (role == null) {
      state = state.copyWith(isLoading: false, error: 'Role not found');
      return;
    }

    final canManage = permissionService.canManageRole(currentUser, role);
    
    state = state.copyWith(
      isLoading: false,
      role: role,
      canManage: canManage,
      maxAllowedPriorityValue: maxAllowedPriority,
    );
  }

  Future<bool> saveRole(UserRole updatedRole) async {
    if (!state.canManage || state.role == null) return false;
    
    // Safety check for priority
    if (updatedRole.priority > state.maxAllowedPriorityValue) {
       state = state.copyWith(error: 'Priority value cannot be higher than ${state.maxAllowedPriorityValue}.');
       return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(roleRepositoryProvider);

    try {
      final result = roleId == 'new' 
        ? await repo.createRole(updatedRole) 
        : await repo.updateRole(updatedRole);

      if (result is Failure) {
        state = state.copyWith(error: result.failure.message);
        return false;
      }
      
      if (roleId == 'new') {
        roleId = updatedRole.id;
      }

      state = state.copyWith(role: updatedRole);
      ref.read(roleListControllerProvider.notifier).loadRoles();
      return true;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
  
  Future<bool> deleteRole() async {
    if (roleId == null || roleId == 'new') return false;
    
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(roleRepositoryProvider);
    
    try {
      final result = await repo.deleteRole(roleId!);
      if (result is Failure) {
        state = state.copyWith(error: result.failure.message);
        return false;
      }
      
      ref.read(roleListControllerProvider.notifier).loadRoles();
      return true;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
