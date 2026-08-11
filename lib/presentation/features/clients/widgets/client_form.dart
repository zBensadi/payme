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
