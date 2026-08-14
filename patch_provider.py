import sys

file_path = "lib/presentation/providers/repository_providers.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# I need to inject `internalUserRepositoryProvider` into `roleRepositoryProvider`
old_provider = """final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final inner = ref.watch(internalRoleRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredRoleRepository(inner, permissionService, currentUser);
});"""

new_provider = """final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final inner = ref.watch(internalRoleRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  final userRepo = ref.watch(internalUserRepositoryProvider);
  return SecuredRoleRepository(inner, permissionService, currentUser, userRepo);
});"""

if old_provider in content:
    content = content.replace(old_provider, new_provider)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
else:
    print("Could not find old_provider")
