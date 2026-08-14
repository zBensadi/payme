import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/domain/entities/user_role.dart';

import 'package:payme/core/error/result.dart';
import 'package:payme/presentation/providers/repository_providers.dart';

final roleListControllerProvider = NotifierProvider<RoleListController, RoleListState>(RoleListController.new);

class RoleListState {
  final bool isLoading;
  final List<UserRole> roles;
  final String? error;

  const RoleListState({
    this.isLoading = false,
    this.roles = const [],
    this.error,
  });

  RoleListState copyWith({
    bool? isLoading,
    List<UserRole>? roles,
    String? error,
    bool clearError = false,
  }) {
    return RoleListState(
      isLoading: isLoading ?? this.isLoading,
      roles: roles ?? this.roles,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RoleListController extends Notifier<RoleListState> {
  @override
  RoleListState build() {
    Future.microtask(() => loadRoles());
    return const RoleListState(isLoading: true);
  }

  Future<void> loadRoles() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(roleRepositoryProvider);

    final result = await repo.getAllRoles();

    if (result is Success<List<UserRole>>) {
      final roles = result.value.where((r) => !r.isDeleted).toList();
      roles.sort((a, b) => a.priority.compareTo(b.priority));
      
      state = state.copyWith(
        isLoading: false,
        roles: roles,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: (result as Failure).failure.message,
      );
    }
  }
}
