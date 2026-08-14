import sys

file_path = "lib/presentation/features/admin/roles/screens/role_editor_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add Delete Role logic
insert_actions = """        actions: [
          if (state.canManage && widget.roleId != 'new' && state.role!.isDeletable)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: state.isSaving ? null : () => _confirmDelete(),
            ),
          if (state.canManage)
            IconButton(
              icon: state.isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
              onPressed: state.isSaving ? null : () => _saveRole(state),
            ),
        ],"""
        
content = content.replace("""        actions: [
          if (state.canManage)
            IconButton(
              icon: state.isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
              onPressed: state.isSaving ? null : () => _saveRole(state),
            ),
        ],""", insert_actions)

delete_method = """  Future<void> _saveRole(RoleEditorState state) async {
"""
new_delete_method = """  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRole),
        content: Text(l10n.deleteRoleConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(roleEditorControllerProvider.notifier).deleteRole();
      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        final state = ref.read(roleEditorControllerProvider);
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _saveRole(RoleEditorState state) async {
"""
content = content.replace(delete_method, new_delete_method)

# Handle title
content = content.replace("title: Text(l10n.editRole)", "title: Text(widget.roleId == 'new' ? l10n.createRole : l10n.editRole)")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
