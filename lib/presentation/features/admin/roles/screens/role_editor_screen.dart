import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../../../utils/failure_localizer.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/entities/permissions.dart';
import 'package:payme/presentation/widgets/error_view.dart';
import '../controllers/role_editor_controller.dart';

class RoleEditorScreen extends ConsumerStatefulWidget {
  final String roleId;

  const RoleEditorScreen({super.key, required this.roleId});

  @override
  ConsumerState<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends ConsumerState<RoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priorityController;

  String? _selectedColorHex;
  Set<String> _selectedPermissions = {};
  String? _populatedRoleId;

  final List<Map<String, dynamic>> _colorPalette = [
    {'name': 'Blue', 'color': Colors.blue, 'hex': '2196F3'},
    {'name': 'Green', 'color': Colors.green, 'hex': '4CAF50'},
    {'name': 'Purple', 'color': Colors.purple, 'hex': '9C27B0'},
    {'name': 'Orange', 'color': Colors.orange, 'hex': 'FF9800'},
    {'name': 'Red', 'color': Colors.red, 'hex': 'F44336'},
    {'name': 'Gray', 'color': Colors.grey, 'hex': '9E9E9E'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _priorityController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roleEditorControllerProvider.notifier).init(widget.roleId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  void _populateForm(UserRole role) {
    if (_populatedRoleId != role.id) {
      _populatedRoleId = role.id;
      _nameController.text = role.name;
      _descController.text = (role.isSystemRole && role.id == 'owner_role')
          ? AppLocalizations.of(context)!.systemOwnerDescription
          : (role.description ?? '');
      _priorityController.text = role.priority.toString();
      _selectedColorHex = role.color?.replaceAll('#', '');
      _selectedPermissions = Set.from(role.permissions);
    }
  }

  void _selectAll() {
    setState(() {
      _selectedPermissions.addAll([
        Permissions.clientsView, Permissions.clientsCreate, Permissions.clientsEdit, Permissions.clientsDelete,
        Permissions.invoicesView, Permissions.invoicesCreate, Permissions.invoicesEdit, Permissions.invoicesDelete,
        Permissions.paymentsView, Permissions.paymentsCreate, Permissions.paymentsEdit, Permissions.paymentsDelete,
        Permissions.accountingYearsView, Permissions.accountingYearsManage,
        Permissions.reportsView, Permissions.exportPdf, Permissions.exportCsv, Permissions.activityView,
        Permissions.dashboardView, Permissions.settingsView, Permissions.settingsEdit, Permissions.backupManage,
        Permissions.usersView, Permissions.usersCreate, Permissions.usersEdit, Permissions.usersDelete,
        Permissions.rolesView, Permissions.rolesManage,
      ]);
    });
  }

  void _deselectAll() {
    setState(() {
      // In the future, if there are specific non-removable permissions for regular roles, handle them here.
      // Currently, owner_role is fully protected by disabled checkboxes, so clearing here is safe for others.
      _selectedPermissions.clear();
    });
  }

  Future<void> _confirmDelete() async {
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!.localize(context)), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _saveRole(RoleEditorState state) async {
    if (!_formKey.currentState!.validate()) return;
    
    final priorityValue = int.tryParse(_priorityController.text) ?? state.maxAllowedPriorityValue;

    final updatedRole = state.role!.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      priority: priorityValue,
      color: _selectedColorHex,
      permissions: _selectedPermissions.toList(),
    );

    final success = await ref.read(roleEditorControllerProvider.notifier).saveRole(updatedRole);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.roleUpdatedSuccess)),
        );
      } else {
        final error = ref.read(roleEditorControllerProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleEditorControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading || state.role == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.roleId == 'new' ? l10n.createRole : l10n.editRole)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.role == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.roleId == 'new' ? l10n.createRole : l10n.editRole)),
        body: ErrorView(
          message: state.error!.localize(context),
          onRetry: () => ref.read(roleEditorControllerProvider.notifier).loadRole(),
        ),
      );
    }

    _populateForm(state.role!);
    final isSystemRole = state.role!.isSystemRole;
    final isEditable = state.role!.isEditable;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roleId == 'new' ? l10n.createRole : l10n.editRole),
        actions: [
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isSystemRole)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.systemRoleWarning, style: const TextStyle(color: Colors.deepOrange))),
                  ],
                ),
              ),
            
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.roleName,
                border: const OutlineInputBorder(),
              ),
              enabled: state.canManage && isEditable,
              validator: (v) => v == null || v.isEmpty ? l10n.errorRequired : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: l10n.roleDescription,
                border: const OutlineInputBorder(),
              ),
              enabled: state.canManage && isEditable,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _priorityController,
              decoration: InputDecoration(
                labelText: l10n.priority,
                border: const OutlineInputBorder(),
                helperText: l10n.priorityDescription,
              ),
              enabled: state.canManage && isEditable,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.errorRequired;
                final parsed = int.tryParse(v);
                if (parsed == null) return l10n.errorInvalidNumber;
                if (parsed > state.maxAllowedPriorityValue) {
                  return 'Maximum value is ${state.maxAllowedPriorityValue}';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            Text(l10n.roleColor, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorPalette.map((item) {
                final isSelected = _selectedColorHex == item['hex'];
                return InkWell(
                  onTap: (state.canManage && isEditable) ? () {
                    setState(() { _selectedColorHex = item['hex']; });
                  } : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item['color'],
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 3) : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.permissionsGroup, style: Theme.of(context).textTheme.titleLarge),
                if (state.canManage && isEditable && widget.roleId != 'owner_role' && widget.roleId != 'role-owner')
                  Row(
                    children: [
                      TextButton(
                        onPressed: _selectAll,
                        child: Text(l10n.selectAll),
                      ),
                      TextButton(
                        onPressed: _deselectAll,
                        child: Text(l10n.deselectAll),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildPermissionGroup(l10n.permissions_clients, [
              Permissions.clientsView,
              Permissions.clientsCreate,
              Permissions.clientsEdit,
              Permissions.clientsDelete,
            ], state.canManage, isEditable),
            
            _buildPermissionGroup(l10n.permissions_invoices, [
              Permissions.invoicesView,
              Permissions.invoicesCreate,
              Permissions.invoicesEdit,
              Permissions.invoicesDelete,
            ], state.canManage, isEditable),
            
            _buildPermissionGroup(l10n.permissions_payments, [
              Permissions.paymentsView,
              Permissions.paymentsCreate,
              Permissions.paymentsEdit,
              Permissions.paymentsDelete,
            ], state.canManage, isEditable),

            _buildPermissionGroup(l10n.permissions_accounting, [
              Permissions.accountingYearsView,
              Permissions.accountingYearsManage,
            ], state.canManage, isEditable),

            _buildPermissionGroup(l10n.permissions_reporting, [
              Permissions.reportsView,
              Permissions.exportPdf,
              Permissions.exportCsv,
              Permissions.activityView,
            ], state.canManage, isEditable),
            
            _buildPermissionGroup(l10n.permissions_system, [
              Permissions.dashboardView,
              Permissions.settingsView,
              Permissions.settingsEdit,
              Permissions.backupManage,
              Permissions.usersView,
              Permissions.usersCreate,
              Permissions.usersEdit,
              Permissions.usersDelete,
              Permissions.rolesView,
              Permissions.rolesManage,
            ], state.canManage, isEditable),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionGroup(String title, List<String> groupPermissions, bool canManage, bool isEditable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: groupPermissions.map((perm) {
          final isOwnerRole = widget.roleId == 'role-owner';
          return CheckboxListTile(
            title: Text(perm),
            value: isOwnerRole ? true : _selectedPermissions.contains(perm),
            onChanged: (canManage && isEditable) ? (bool? checked) {
              setState(() {
                if (checked == true) {
                  _selectedPermissions.add(perm);
                } else {
                  _selectedPermissions.remove(perm);
                }
              });
            } : null,
          );
        }).toList(),
      ),
    );
  }
}
