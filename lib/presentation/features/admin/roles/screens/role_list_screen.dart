import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:payme/l10n/app_localizations.dart';
import '../../../../utils/failure_localizer.dart';

import 'package:payme/domain/entities/permissions.dart';
import 'package:payme/presentation/widgets/require_permission.dart';
import 'package:payme/presentation/widgets/error_view.dart';
import 'package:payme/presentation/utils/sync_refresh_helper.dart';
import '../../../../../presentation/utils/sync_refresh_helper.dart';
import '../../../../../presentation/widgets/sync_refresh_button.dart';
import '../controllers/role_list_controller.dart';
import '../widgets/role_list_tile.dart';
import '../../../../utils/plus_action_registry.dart';
import '../../../auth/controllers/current_user_controller.dart';
import '../../../../providers/permission_service_provider.dart';

class RoleListScreen extends ConsumerStatefulWidget {
  const RoleListScreen({super.key});

  @override
  ConsumerState<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends ConsumerState<RoleListScreen> {
  PlusActionRegistration? _plusReg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _plusReg = ref.read(plusActionRegistryProvider).push('RoleList', _createRole);
      }
    });
  }

  @override
  void dispose() {
    _plusReg?.dispose();
    super.dispose();
  }

  void _createRole() {
    if (!mounted) return;
    
    // The FAB is hidden by RequirePermission if unauthorized.
    // The keyboard shortcut could bypass the UI hiding, so we must check here too.
    final currentUser = ref.read(currentUserProvider).value;
    final permissionService = ref.read(permissionServiceProvider);
    
    if (permissionService.hasPermission(currentUser, Permissions.rolesManage)) {
      context.push('/roles/new');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleListControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rolesListTitle),
        actions: [
          const SyncRefreshButton(),
        ],
      ),
      body: _buildBody(context, state, l10n),
      floatingActionButton: RequirePermission(
        permission: Permissions.rolesManage,
        child: FloatingActionButton(
          onPressed: _createRole,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RoleListState state, AppLocalizations l10n) {
    if (state.isLoading && state.roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.roles.isEmpty) {
      return ErrorView(
        message: state.error!.localize(context),
        onRetry: () => ref.read(roleListControllerProvider.notifier).loadRoles(),
      );
    }

    if (state.roles.isEmpty) {
      return Center(
        child: Text(
          l10n.noRolesFound,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => SyncRefreshHelper.refresh(ref),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.roles.length,
        itemBuilder: (context, index) {
          final role = state.roles[index];
          return RoleListTile(role: role);
        },
      ),
    );
  }
}
