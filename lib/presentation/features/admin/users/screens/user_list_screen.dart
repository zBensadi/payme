import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../../../utils/failure_localizer.dart';

import '../controllers/user_list_controller.dart';
import '../widgets/user_list_tile.dart';
import '../../../../../presentation/utils/sync_refresh_helper.dart';
import '../../../../../presentation/widgets/sync_refresh_button.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../utils/sync_refresh_helper.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userListControllerProvider);
    final notifier = ref.read(userListControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.users),
        actions: [
          const SyncRefreshButton(),
          IconButton(
            icon: Icon(state.showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: state.showInactive ? l10n.hideInactiveUsers : l10n.showInactiveUsers,
            onPressed: () {
              notifier.toggleShowInactive(!state.showInactive);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchUsers,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => notifier.setSearchQuery(value),
            ),
          ),
        ),
      ),
      body: state.isLoading && state.allUsers.isEmpty
          ? LoadingView(message: l10n.loading)
          : state.error != null && state.allUsers.isEmpty
              ? ErrorView(
                  message: state.error!.localize(context),
                  onRetry: () => notifier.loadData(),
                )
              : RefreshIndicator(
                  onRefresh: () => SyncRefreshHelper.refresh(ref),
                  child: state.filteredUsers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Text(l10n.noUsersFound),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: state.filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = state.filteredUsers[index];
                            final role = user.roleId != null ? state.rolesMap[user.roleId] : null;
                            return UserListTile(
                              user: user,
                              role: role,
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/users/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
