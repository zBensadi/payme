import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../../../../domain/entities/business_settings.dart';
import '../controllers/settings_controller.dart';
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
  late TextEditingController _documentTitleController;
  late TextEditingController _rcController;
  late TextEditingController _nifController;
  late TextEditingController _nisController;
  late TextEditingController _artController;
  String _currencyCode = 'USD';
  String _languageCode = 'en';
  String _documentLayout = 'standard';
  String? _newLogoPath;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _documentTitleController = TextEditingController();
    _rcController = TextEditingController();
    _nifController = TextEditingController();
    _nisController = TextEditingController();
    _artController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _documentTitleController.dispose();
    _rcController.dispose();
    _nifController.dispose();
    _nisController.dispose();
    _artController.dispose();
    super.dispose();
  }

  void _populateForm(BusinessSettings settings) {
    if (_businessNameController.text.isEmpty && settings.businessName != null) {
      _businessNameController.text = settings.businessName!;
      _addressController.text = settings.address ?? '';
      _phoneController.text = settings.phone ?? '';
      _emailController.text = settings.email ?? '';
      _rcController.text = settings.rc ?? '';
      _nifController.text = settings.nif ?? '';
      _nisController.text = settings.nis ?? '';
      _artController.text = settings.art ?? '';
      _currencyCode = settings.currencyCode;
      _languageCode = settings.languageCode;
      _documentTitleController.text = settings.defaultDocumentTitle;
      _documentLayout = settings.defaultDocumentLayout;
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
          defaultDocumentTitle: _documentTitleController.text,
          defaultDocumentLayout: _documentLayout,
          rc: _rcController.text.trim().isEmpty ? null : _rcController.text.trim(),
          nif: _nifController.text.trim().isEmpty ? null : _nifController.text.trim(),
          nis: _nisController.text.trim().isEmpty ? null : _nisController.text.trim(),
          art: _artController.text.trim().isEmpty ? null : _artController.text.trim(),
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
      ),
      body: settingsState.when(
        data: (settings) {
          _populateForm(settings);
          
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCard(
                  title: context.l10n.business,
                  children: [
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: context.l10n.address, border: const OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rcController,
                      maxLength: 50,
                      decoration: InputDecoration(labelText: context.l10n.rc, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nifController,
                      maxLength: 50,
                      decoration: InputDecoration(labelText: context.l10n.nif, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nisController,
                      maxLength: 50,
                      decoration: InputDecoration(labelText: context.l10n.nis, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _artController,
                      maxLength: 50,
                      decoration: InputDecoration(labelText: context.l10n.art, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
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
                  ],
                ),
                
                _buildCard(
                  title: context.l10n.localization,
                  children: [
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
                  ],
                ),
                
                _buildCard(
                  title: context.l10n.printing,
                  children: [
                    TextFormField(
                      controller: _documentTitleController,
                      decoration: InputDecoration(labelText: context.l10n.documentTitle, border: const OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _documentLayout,
                      decoration: InputDecoration(labelText: context.l10n.documentLayout, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'standard', child: Text(context.l10n.layoutStandard)),
                        DropdownMenuItem(value: 'duplicate', child: Text(context.l10n.layoutDuplicate)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _documentLayout = val);
                        }
                      },
                    ),
                  ],
                ),
                
                _buildCard(
                  title: context.l10n.data,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.backup),
                      title: Text(context.l10n.backupAndRestore),
                      onTap: () => context.push('/backup'),
                    ),
                  ],
                ),
                
                _buildCard(
                  title: context.l10n.security,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.security),
                      title: Text(context.l10n.changePasswordTitle),
                      onTap: () => context.push('/settings/change-password'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: Text(context.l10n.saveSettings, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => LoadingView(message: context.l10n.loadingSettings),
        error: (error, _) => ErrorView(
          message: error.toString().localize(context),
          onRetry: () => ref.invalidate(settingsControllerProvider),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
