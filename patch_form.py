import sys

file_path = "lib/presentation/features/clients/widgets/client_form.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add imports
if "core/error/result.dart" not in content:
    content = content.replace(
        "import '../../../../domain/entities/current_app_user.dart';",
        "import '../../../../domain/entities/current_app_user.dart';\nimport '../../../../core/error/result.dart';\nimport '../../../../domain/entities/app_user.dart';"
    )

# 2. Fix usersResult checks
content = content.replace("if (usersResult.isError || !mounted) return;", "if (usersResult is Failure || !mounted) return;")
content = content.replace("final allUsers = usersResult.value;", "final allUsers = (usersResult as Success<List<AppUser>>).value;")

# 3. Fix _UserSelectionDialog declaration
content = content.replace("final List<CurrentAppUser> allUsers;", "final List<AppUser> allUsers;")

# 4. Fix _UserSelectionDialogState building
old_item_builder = """          itemBuilder: (context, index) {
            final user = widget.allUsers[index];
            final isSelected = _selectedIds.contains(user.user.id);
            return CheckboxListTile(
              title: Text(user.user.displayName ?? user.user.email),
              subtitle: Text(user.role.name),
              value: isSelected,
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _selectedIds.add(user.user.id);
                  } else {
                    _selectedIds.remove(user.user.id);
                  }
                });
              },
            );
          },"""

new_item_builder = """          itemBuilder: (context, index) {
            final user = widget.allUsers[index];
            final isSelected = _selectedIds.contains(user.uid);
            return CheckboxListTile(
              title: Text(user.displayName ?? user.email),
              subtitle: Text(user.email),
              value: isSelected,
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _selectedIds.add(user.uid);
                  } else {
                    _selectedIds.remove(user.uid);
                  }
                });
              },
            );
          },"""

content = content.replace(old_item_builder, new_item_builder)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

