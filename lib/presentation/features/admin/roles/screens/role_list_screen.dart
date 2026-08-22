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

class RoleListScreen extends ConsumerWidget {
  const RoleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleListControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rolesListTitle),
        actions: [
          const SyncRefreshButton(),
        ],
      ),
      body: _buildBody(context, ref, state, l10n),
      floatingActionButton: RequirePermission(
        permission: Permissions.rolesManage,
        child: FloatingActionButton(
          onPressed: () {
            context.push('/roles/new');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, RoleListState state, AppLocalizations l10n) {
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
