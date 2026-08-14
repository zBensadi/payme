import sys

file_path = "lib/presentation/features/admin/roles/controllers/role_editor_controller.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Make UUID import available
content = content.replace("import 'role_list_controller.dart';", "import 'role_list_controller.dart';\nimport 'package:uuid/uuid.dart';")

# 1. Modify loadRole
old_load = """  Future<void> loadRole() async {
    if (roleId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    
    final repo = ref.read(roleRepositoryProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final currentUser = ref.read(currentUserProvider).value;

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
    
    int minAllowedPriority = 1000;
    if (currentUser?.user.isOwner == true) {
      minAllowedPriority = 1; 
    } else if (currentUser != null) {
      minAllowedPriority = currentUser.role.priority + 1;
    }

    state = state.copyWith(
      isLoading: false,
      role: role,
      canManage: canManage,
      minAllowedPriorityValue: minAllowedPriority,
    );
  }"""

new_load = """  Future<void> loadRole() async {
    if (roleId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    
    final repo = ref.read(roleRepositoryProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final currentUser = ref.read(currentUserProvider).value;

    int minAllowedPriority = 1000;
    if (currentUser?.user.isOwner == true) {
      minAllowedPriority = 1; 
    } else if (currentUser != null) {
      minAllowedPriority = currentUser.role.priority + 1;
    }

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
        minAllowedPriorityValue: minAllowedPriority,
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
      minAllowedPriorityValue: minAllowedPriority,
    );
  }"""

content = content.replace(old_load, new_load)

# 2. Modify saveRole
old_save = """  Future<bool> saveRole(UserRole updatedRole) async {
    if (!state.canManage || state.role == null) return false;
    
    // Safety check for priority
    if (updatedRole.priority < state.minAllowedPriorityValue) {
       state = state.copyWith(error: 'Priority value cannot be lower than ${state.minAllowedPriorityValue}.');
       return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(roleRepositoryProvider);

    final result = await repo.updateRole(updatedRole);

    if (result is Failure) {
      state = state.copyWith(
        isSaving: false,
        error: result.failure.message,
      );
      return false;
    }

    state = state.copyWith(
      isSaving: false,
      role: updatedRole,
    );
    ref.read(roleListControllerProvider.notifier).loadRoles();
    return true;
  }"""

new_save = """  Future<bool> saveRole(UserRole updatedRole) async {
    if (!state.canManage || state.role == null) return false;
    
    // Safety check for priority
    if (updatedRole.priority < state.minAllowedPriorityValue) {
       state = state.copyWith(error: 'Priority value cannot be lower than ${state.minAllowedPriorityValue}.');
       return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(roleRepositoryProvider);

    final result = roleId == 'new' 
      ? await repo.createRole(updatedRole) 
      : await repo.updateRole(updatedRole);

    if (result is Failure) {
      state = state.copyWith(
        isSaving: false,
        error: result.failure.message,
      );
      return false;
    }
    
    if (roleId == 'new') {
      roleId = updatedRole.id;
    }

    state = state.copyWith(
      isSaving: false,
      role: updatedRole,
    );
    ref.read(roleListControllerProvider.notifier).loadRoles();
    return true;
  }
  
  Future<bool> deleteRole() async {
    if (roleId == null || roleId == 'new') return false;
    
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(roleRepositoryProvider);
    
    final result = await repo.deleteRole(roleId!);
    if (result is Failure) {
      state = state.copyWith(
        isSaving: false,
        error: result.failure.message,
      );
      return false;
    }
    
    ref.read(roleListControllerProvider.notifier).loadRoles();
    return true;
  }"""
  
content = content.replace(old_save, new_save)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
