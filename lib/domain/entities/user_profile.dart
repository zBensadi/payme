import 'app_user.dart';
import 'business_context.dart';
import 'user_role.dart';

class UserProfile {
  final AppUser user;
  final BusinessContext? businessContext;
  final UserRole? role;

  const UserProfile({
    required this.user,
    this.businessContext,
    this.role,
  });

  bool get requiresBootstrap => user.businessId == null || businessContext == null;
}
