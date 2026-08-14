import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/user_role.dart';
import '../../../../../domain/repositories/user_repository.dart';
import '../../../../../domain/repositories/role_repository.dart';
import '../../../../../core/error/result.dart';
import '../../../../providers/repository_providers.dart';

class UserListState {
  final bool isLoading;
  final String? error;
  final List<AppUser> allUsers;
  final List<AppUser> filteredUsers;
  final Map<String, UserRole> rolesMap;
  final String searchQuery;
  final bool showInactive;

  const UserListState({
    this.isLoading = false,
    this.error,
    this.allUsers = const [],
    this.filteredUsers = const [],
    this.rolesMap = const {},
    this.searchQuery = '',
    this.showInactive = true,
  });

  UserListState copyWith({
    bool? isLoading,
    String? error,
    List<AppUser>? allUsers,
    List<AppUser>? filteredUsers,
    Map<String, UserRole>? rolesMap,
    String? searchQuery,
    bool? showInactive,
  }) {
    return UserListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      rolesMap: rolesMap ?? this.rolesMap,
      searchQuery: searchQuery ?? this.searchQuery,
      showInactive: showInactive ?? this.showInactive,
    );
  }
}

class UserListController extends Notifier<UserListState> {
  late UserRepository _userRepository;
  late RoleRepository _roleRepository;

  @override
  UserListState build() {
    _userRepository = ref.watch(userRepositoryProvider);
    _roleRepository = ref.watch(roleRepositoryProvider);
    
    Future.microtask(() => loadData());
    
    return const UserListState();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    final usersResult = await _userRepository.getAllUsers();
    final rolesResult = await _roleRepository.getAllRoles();

    if (usersResult is Failure || rolesResult is Failure) {
      final error = usersResult is Failure ? (usersResult as Failure).failure.message : (rolesResult as Failure).failure.message;
      state = state.copyWith(isLoading: false, error: error);
      return;
    }

    final users = (usersResult as Success<List<AppUser>>).value;
    final roles = (rolesResult as Success<List<UserRole>>).value;

    final rolesMap = {for (var role in roles) role.id: role};

    // Filter out logically deleted users from the active list view entirely.
    final nonDeletedUsers = users.where((u) => !u.isDeleted).toList();

    state = state.copyWith(
      isLoading: false,
      allUsers: nonDeletedUsers,
      rolesMap: rolesMap,
    );

    _applyFilters();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void toggleShowInactive(bool show) {
    state = state.copyWith(showInactive: show);
    _applyFilters();
  }

  void _applyFilters() {
    List<AppUser> filtered = state.allUsers;

    if (!state.showInactive) {
      filtered = filtered.where((u) => u.isActive).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        final name = (u.displayName ?? '').toLowerCase();
        final email = u.email.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Sort by role priority, then by name
    filtered.sort((a, b) {
      final roleA = a.roleId != null ? state.rolesMap[a.roleId] : null;
      final roleB = b.roleId != null ? state.rolesMap[b.roleId] : null;
      
      final priorityA = roleA?.priority ?? 0;
      final priorityB = roleB?.priority ?? 0;
      
      if (priorityA != priorityB) {
        return priorityB.compareTo(priorityA); // Highest priority first
      }
      
      final nameA = (a.displayName ?? a.email).toLowerCase();
      final nameB = (b.displayName ?? b.email).toLowerCase();
      return nameA.compareTo(nameB);
    });

    state = state.copyWith(filteredUsers: filtered);
  }

  Future<void> deactivateUser(AppUser user) async {
    final updatedUser = user.copyWith(isActive: false, isDirty: true, updatedAt: DateTime.now().toUtc());
    final result = await _userRepository.updateUser(updatedUser);
    
    if (result is Success) {
      await loadData();
    } else {
      state = state.copyWith(error: (result as Failure).failure.message);
    }
  }

  Future<void> activateUser(AppUser user) async {
    final updatedUser = user.copyWith(isActive: true, isDirty: true, updatedAt: DateTime.now().toUtc());
    final result = await _userRepository.updateUser(updatedUser);
    
    if (result is Success) {
      await loadData();
    } else {
      state = state.copyWith(error: (result as Failure).failure.message);
    }
  }
}

final userListControllerProvider = NotifierProvider<UserListController, UserListState>(UserListController.new);

