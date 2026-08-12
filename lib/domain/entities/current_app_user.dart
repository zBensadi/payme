import 'app_user.dart';
import 'user_role.dart';

class CurrentAppUser {
  final AppUser user;
  final UserRole role;

  const CurrentAppUser({
    required this.user,
    required this.role,
  });
}
