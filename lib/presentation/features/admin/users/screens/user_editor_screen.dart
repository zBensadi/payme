import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../../../utils/failure_localizer.dart';

import '../controllers/user_editor_controller.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';

class UserEditorScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserEditorScreen({super.key, required this.userId});

  @override
  ConsumerState<UserEditorScreen> createState() => _UserEditorScreenState();
}

class _UserEditorScreenState extends ConsumerState<UserEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRoleId;
  String? _populatedUserId;

  void _populateForm(user) {
    if (_populatedUserId != user.uid) {
      _populatedUserId = user.uid;
      _emailController.text = user.email;
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userEditorControllerProvider.notifier).init(widget.userId);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userEditorControllerProvider);
    final notifier = ref.read(userEditorControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.userId == 'new' ? 'Create User' : l10n.userDetails)),
        body: LoadingView(message: l10n.loading),
      );
    }

    if (state.error != null && state.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.userId == 'new' ? 'Create User' : l10n.userDetails)),
        body: ErrorView(
          message: state.error!.localize(context),
          onRetry: () => notifier.loadUser(),
        ),
      );
    }

    final user = state.user!;
    final role = state.currentRole;

    _populateForm(user);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isNewUser ? ('Create User') : (user.displayName ?? user.email)),
        actions: [
          if (state.canDelete && !user.isOwner && !state.isNewUser)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.deleteUser),
                    content: Text(l10n.deleteUserWarning),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await notifier.softDelete();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.userDeletedSuccess)),
                    );
                    context.pop();
                  } else if (context.mounted && state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error!.localize(context)), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: state.isSaving
          ? LoadingView(message: l10n.loading)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: state.isNewUser ? _buildCreateForm(context, state, notifier, l10n) : _buildEditView(context, state, notifier, l10n, user, role),
            ),
    );
  }

  Widget _buildCreateForm(BuildContext context, UserEditorState state, UserEditorController notifier, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(state.error!.localize(context), style: const TextStyle(color: Colors.red)),
            ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Display Name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Initial Password', border: OutlineInputBorder()),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRoleId,
            decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
            items: state.availableRoles.map((r) {
              return DropdownMenuItem(value: r.id, child: Text(r.name));
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Role is required';
              return null;
            },
            onChanged: (val) {
              setState(() {
                _selectedRoleId = val;
              });
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final success = await notifier.saveNewUser(
                    email: _emailController.text,
                    displayName: _nameController.text,
                    password: _passwordController.text,
                    roleId: _selectedRoleId!,
                  );
                  // Password cleared immediately after save is requested
                  _passwordController.clear();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User created successfully')),
                    );
                    context.pop();
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditView(BuildContext context, UserEditorState state, UserEditorController notifier, AppLocalizations l10n, user, role) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.isOwner)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is the System Owner account. It cannot be deactivated, deleted, or reassigned.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          
          if (state.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(state.error!.localize(context), style: const TextStyle(color: Colors.red)),
            ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.email, 
                      border: const OutlineInputBorder(),
                      helperText: 'Email cannot be changed directly.',
                    ),
                    readOnly: true, // As per requirements, email updating via UI is restricted unless supported
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.businessName, border: const OutlineInputBorder()),
                    readOnly: !state.canEdit,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Display Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(l10n.roleId, role?.name ?? l10n.unknownRole),
                  const Divider(),
                  _buildDetailRow(l10n.statusLabel, user.isActive ? 'Active' : 'Inactive'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (state.canEdit)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final success = await notifier.updateUser(
                      displayName: _nameController.text,
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.userUpdatedSuccess)),
                      );
                    }
                  }
                },
                child: const Text('Save Profile'),
              ),
            ),
            
          const SizedBox(height: 24),
          if (state.canEdit && !user.isOwner) ...[
            Text(l10n.administration, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: state.availableRoles.any((r) => r.id == user.roleId) ? user.roleId : null,
                      decoration: InputDecoration(
                        labelText: l10n.changeRole,
                        border: const OutlineInputBorder(),
                      ),
                      items: state.availableRoles.map((r) {
                        return DropdownMenuItem(value: r.id, child: Text(r.name));
                      }).toList(),
                      onChanged: (newRoleId) async {
                        if (newRoleId != null && newRoleId != user.roleId) {
                          final success = await notifier.changeRole(newRoleId);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.userUpdatedSuccess)),
                            );
                          }
                        }
                      },
                      disabledHint: Text(user.roleId != null && role != null ? role.name : l10n.unknownRole),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: Text(user.isActive ? l10n.active : l10n.inactive),
                      subtitle: Text(user.isActive ? 'User will lose access to the system immediately.' : 'User will regain access to the system.'),
                      value: user.isActive,
                      onChanged: (value) async {
                        if (!value) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.deactivateUser),
                              content: Text(l10n.deactivateWarning),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.deactivateUser, style: const TextStyle(color: Colors.orange))),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }
                        final success = await notifier.toggleActive(value);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.userUpdatedSuccess)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}




