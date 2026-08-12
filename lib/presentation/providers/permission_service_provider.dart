import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/permission_service.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});
