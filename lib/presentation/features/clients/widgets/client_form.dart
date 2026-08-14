import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/client.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../controllers/client_form_controller.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../providers/repository_providers.dart';


final _allUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final repo = ref.read(internalUserRepositoryProvider);
  final result = await repo.getAllUsers();
  if (result is Success<List<AppUser>>) {
    return result.value;
  }
  return [];
});

class ClientForm extends ConsumerStatefulWidget {

  final Client? initialClient;
  final void Function(Client client) onSave;

  const ClientForm({
    super.key,
    this.initialClient,
    required this.onSave,
  });

  @override
  ConsumerState<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _rcController;
  late TextEditingController _nifController;
  late TextEditingController _nisController;
  late TextEditingController _artController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialClient?.name);
    _phoneController = TextEditingController(text: widget.initialClient?.phone);
    _emailController = TextEditingController(text: widget.initialClient?.email);
    _addressController = TextEditingController(text: widget.initialClient?.address);
    _notesController = TextEditingController(text: widget.initialClient?.notes);
    _rcController = TextEditingController(text: widget.initialClient?.rc);
    _nifController = TextEditingController(text: widget.initialClient?.nif);
    _nisController = TextEditingController(text: widget.initialClient?.nis);
    _artController = TextEditingController(text: widget.initialClient?.art);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _rcController.dispose();
    _nifController.dispose();
    _nisController.dispose();
    _artController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final client = widget.initialClient?.copyWith(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
            notes: _notesController.text.trim(),
            rc: _rcController.text.trim().isEmpty ? null : _rcController.text.trim(),
            nif: _nifController.text.trim().isEmpty ? null : _nifController.text.trim(),
            nis: _nisController.text.trim().isEmpty ? null : _nisController.text.trim(),
            art: _artController.text.trim().isEmpty ? null : _artController.text.trim(),
          ) ??
          Client(
            id: '',
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
            notes: _notesController.text.trim(),
            rc: _rcController.text.trim().isEmpty ? null : _rcController.text.trim(),
            nif: _nifController.text.trim().isEmpty ? null : _nifController.text.trim(),
            nis: _nisController.text.trim().isEmpty ? null : _nisController.text.trim(),
            art: _artController.text.trim().isEmpty ? null : _artController.text.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
      widget.onSave(client);
    }
  }

  Future<void> _showUserPicker() async {
    final userRepository = ref.read(internalUserRepositoryProvider);
    final usersResult = await userRepository.getAllUsers();
    
    if (usersResult is Failure || !mounted) return;
    
    final allUsers = (usersResult as Success<List<AppUser>>).value;
    final currentState = ref.read(clientFormControllerProvider).value!;
    
    final selectedIds = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return _UserSelectionDialog(
          allUsers: allUsers,
          initialSelectedIds: currentState.selectedUserIds,
        );
      },
    );
    
    if (selectedIds != null && mounted) {
      ref.read(clientFormControllerProvider.notifier).setSelectedUsers(selectedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(clientFormControllerProvider).value;
    final usersAsync = ref.watch(_allUsersProvider);
    if (formState == null) return const SizedBox.shrink();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.clientNameLabel,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.errorEnterName;
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            autofocus: widget.initialClient == null,
          ),
          const SizedBox(height: 16),
          
          // Visibility Section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.clientVisibility,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'everyone', label: Text(AppLocalizations.of(context)!.visibilityEveryone)),
                      ButtonSegment(value: 'specific_users', label: Text(AppLocalizations.of(context)!.visibilitySpecificUsers)),
                    ],
                    selected: {formState.visibilityType},
                    onSelectionChanged: (Set<String> newSelection) {
                      ref.read(clientFormControllerProvider.notifier).setVisibilityType(newSelection.first);
                    },
                  ),
                  if (formState.visibilityType == 'specific_users') ...[
                    const SizedBox(height: 16),
                    if (formState.selectedUserIds.isEmpty)
                      Text(AppLocalizations.of(context)!.noUsersSelected, style: const TextStyle(color: Colors.grey)),
                    if (formState.selectedUserIds.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: formState.selectedUserIds.map((id) {
                          final user = usersAsync.value?.where((u) => u.uid == id).firstOrNull;
                          final displayName = (user?.displayName?.trim().isNotEmpty == true) 
                              ? user!.displayName! 
                              : (user?.email?.trim().isNotEmpty == true) 
                                  ? user!.email! 
                                  : id;
                          print('[TRACE-VISIBILITY] UI Chip mapping: selectedUserId=$id, totalUsers=${usersAsync.value?.length}, matchedUserUid=${user?.uid}, displayName=${user?.displayName}, email=${user?.email}, rendered=$displayName');
                          return Chip(
                            label: Text(displayName),
                            onDeleted: () {
                              final newIds = List<String>.from(formState.selectedUserIds)..remove(id);
                              ref.read(clientFormControllerProvider.notifier).setSelectedUsers(newIds);
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showUserPicker,
                      icon: const Icon(Icons.person_add),
                      label: Text(AppLocalizations.of(context)!.selectUsers),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.phoneOptional,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.emailOptional,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.addressOptional,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.notesOptional,
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.legalInformation,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rcController,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.rc,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nifController,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.nif,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nisController,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.nis,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _artController,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.art,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(AppLocalizations.of(context)!.saveClient),
          ),
        ],
      ),
    );
  }
}

class _UserSelectionDialog extends StatefulWidget {
  final List<AppUser> allUsers;
  final List<String> initialSelectedIds;

  const _UserSelectionDialog({
    required this.allUsers,
    required this.initialSelectedIds,
  });

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectUsers),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allUsers.length,
          itemBuilder: (context, index) {
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
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
