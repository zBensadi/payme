import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';
import '../providers/permission_service_provider.dart';
import '../features/auth/controllers/current_user_controller.dart';

class RequirePermission extends ConsumerWidget {
  final String permission;
  final Widget child;
  final Widget fallback;

  const RequirePermission({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final permissionService = ref.watch(permissionServiceProvider);

    if (permissionService.hasPermission(currentUser, permission)) {
      return child;
    }
    return fallback;
  }
}

extension RequirePermissionExtension on Widget {
  Widget requirePermission(String permission, {Widget fallback = const SizedBox.shrink()}) {
    return RequirePermission(
      permission: permission,
      fallback: fallback,
      child: this,
    );
  }
}
