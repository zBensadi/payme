import sys
import re

file_path = "lib/presentation/features/clients/widgets/client_form.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add FutureProvider
provider_code = """
final _allUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final repo = ref.read(internalUserRepositoryProvider);
  final result = await repo.getAllUsers();
  if (result is Success<List<AppUser>>) {
    return result.value;
  }
  return [];
});

class ClientForm extends ConsumerStatefulWidget {
"""
content = content.replace("class ClientForm extends ConsumerStatefulWidget {", provider_code)

# Add ref.watch to build method
watch_code = """
  @override
  Widget build(BuildContext context) {
    final formStateAsync = ref.watch(clientFormControllerProvider);
    final usersAsync = ref.watch(_allUsersProvider);
"""
content = content.replace("  @override\n  Widget build(BuildContext context) {\n    final formStateAsync = ref.watch(clientFormControllerProvider);", watch_code)

# Update Chip
chip_old = """
                          children: formState.selectedUserIds.map((id) {
                            return Chip(
                              label: Text(id), // Ideally we would map this to the user's name
"""
chip_new = """
                          children: formState.selectedUserIds.map((id) {
                            final user = usersAsync.valueOrNull?.where((u) => u.uid == id).firstOrNull;
                            final displayName = user?.displayName ?? user?.email ?? id;
                            return Chip(
                              label: Text(displayName),
"""
content = content.replace(chip_old, chip_new)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

