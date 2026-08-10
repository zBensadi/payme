import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../../../../domain/entities/business_settings.dart';
import '../controllers/settings_controller.dart';
import '../../auth/controllers/firebase_auth_controller.dart';
import '../widgets/logo_picker.dart';
import '../../../../core/extensions/l10n_extension.dart';
import '../../../providers/locale_controller.dart';
import '../../../../core/constants/supported_locales.dart';

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
          languageCode: _languageCode, // Preserve existing value
          newLogoSourcePath: _newLogoPath,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.settingsSaved), backgroundColor: Colors.green),
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
        title: Text(context.l10n.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: context.l10n.backupAndRestore,
            onPressed: () => context.push('/backup'),
          ),
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: context.l10n.changePasswordTitle,
            onPressed: () => context.push('/settings/change-password'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(firebaseAuthControllerProvider.notifier).logout();
            },
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
                Text(context.l10n.businessInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                LogoPicker(
                  initialLogoPath: settings.logoPath,
                  onLogoSelected: (path) => _newLogoPath = path,
                ),
                
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(labelText: context.l10n.businessName, border: const OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? context.l10n.businessNameRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: context.l10n.address, border: const OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: context.l10n.phoneNumber, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: context.l10n.email, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                
                Text(context.l10n.preferences, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                DropdownButtonFormField<String>(
                  initialValue: _currencyCode,
                  decoration: InputDecoration(labelText: context.l10n.baseCurrency, border: const OutlineInputBorder()),
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
                  initialValue: ref.watch(localeControllerProvider)?.languageCode ?? 'en',
                  decoration: InputDecoration(labelText: context.l10n.applicationLanguage, border: const OutlineInputBorder()),
                  items: SupportedLocales.all.map((locale) {
                    return DropdownMenuItem(
                      value: locale.languageCode, 
                      child: Text(SupportedLocales.getLanguageName(locale.languageCode))
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(localeControllerProvider.notifier).setLocale(val);
                    }
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: Text(context.l10n.saveSettings, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => LoadingView(message: context.l10n.loadingSettings),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(settingsControllerProvider),
        ),
      ),
    );
  }
}
