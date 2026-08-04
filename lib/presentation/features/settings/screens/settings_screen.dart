import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../../../../domain/entities/business_settings.dart';
import '../controllers/settings_controller.dart';
import '../widgets/logo_picker.dart';
import 'package:payme/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String _currencyCode = 'USD';
  String _languageCode = 'en';
  String? _newLogoPath;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateForm(BusinessSettings settings) {
    if (_businessNameController.text.isEmpty && settings.businessName != null) {
      _businessNameController.text = settings.businessName!;
      _addressController.text = settings.address ?? '';
      _phoneController.text = settings.phone ?? '';
      _emailController.text = settings.email ?? '';
      _currencyCode = settings.currencyCode;
      _languageCode = settings.languageCode;
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(settingsControllerProvider.notifier).updateSettings(
          businessName: _businessNameController.text,
          address: _addressController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          currencyCode: _currencyCode,
          languageCode: _languageCode,
          newLogoSourcePath: _newLogoPath,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: AppLocalizations.of(context)!.backupAndRestore,
            onPressed: () => context.push('/backup'),
          ),
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: AppLocalizations.of(context)!.changePasswordTitle,
            onPressed: () => context.push('/settings/change-password'),
          ),
        ],
      ),
      body: settingsState.when(
        data: (settings) {
          _populateForm(settings);
          
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(AppLocalizations.of(context)!.businessInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                LogoPicker(
                  initialLogoPath: settings.logoPath,
                  onLogoSelected: (path) => _newLogoPath = path,
                ),
                
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.businessName, border: const OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.businessNameRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.address, border: const OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.phoneNumber, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                
                Text(AppLocalizations.of(context)!.preferences, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                DropdownButtonFormField<String>(
                  initialValue: _currencyCode,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.baseCurrency, border: const OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP - British Pound')),
                    DropdownMenuItem(value: 'DZD', child: Text('DZD - Algerian Dinar')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _currencyCode = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  initialValue: _languageCode,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.language, border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(AppLocalizations.of(context)!.english)),
                    DropdownMenuItem(value: 'fr', child: Text(AppLocalizations.of(context)!.french)),
                    DropdownMenuItem(value: 'ar', child: Text(AppLocalizations.of(context)!.arabic)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _languageCode = val);
                    }
                  },
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: Text(AppLocalizations.of(context)!.saveSettings, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => LoadingView(message: AppLocalizations.of(context)!.loadingSettings),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(settingsControllerProvider),
        ),
      ),
    );
  }
}
