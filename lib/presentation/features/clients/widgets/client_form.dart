import 'package:flutter/material.dart';
import '../../../../domain/entities/client.dart';
import 'package:payme/l10n/app_localizations.dart';

class ClientForm extends StatefulWidget {
  final Client? initialClient;
  final void Function(Client client) onSave;

  const ClientForm({
    super.key,
    this.initialClient,
    required this.onSave,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialClient?.name);
    _phoneController = TextEditingController(text: widget.initialClient?.phone);
    _emailController = TextEditingController(text: widget.initialClient?.email);
    _addressController = TextEditingController(text: widget.initialClient?.address);
    _notesController = TextEditingController(text: widget.initialClient?.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
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
          ) ??
          Client(
            id: '',
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
            notes: _notesController.text.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
      widget.onSave(client);
    }
  }

  @override
  Widget build(BuildContext context) {
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
