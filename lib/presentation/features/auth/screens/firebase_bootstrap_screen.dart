import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payme/l10n/app_localizations.dart';

import '../../../../services/business_bootstrap_service.dart';
import '../../../../core/error/result.dart';
import '../controllers/current_user_controller.dart';

class FirebaseBootstrapScreen extends ConsumerStatefulWidget {
  const FirebaseBootstrapScreen({super.key});

  @override
  ConsumerState<FirebaseBootstrapScreen> createState() => _FirebaseBootstrapScreenState();
}

class _FirebaseBootstrapScreenState extends ConsumerState<FirebaseBootstrapScreen> {
  final _businessNameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final businessName = _businessNameController.text.trim();
    if (businessName.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context)!.businessNameRequired;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final bootstrapService = ref.read(businessBootstrapServiceProvider);
    final result = await bootstrapService.bootstrapBusiness(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      businessName: businessName,
    );

    if (!mounted) return;

    if (result is Failure) {
      setState(() {
        _isLoading = false;
        _error = (result as Failure).failure.message;
      });
    } else {
      // Notify the current user provider to re-fetch the user profile from Firestore,
      // which will naturally emit a new state and cause the router to navigate.
      ref.invalidate(currentUserProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.business, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.welcomeToPayMe,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.bootstrapInstructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _businessNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.businessName,
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _bootstrap(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _bootstrap,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.completeSetup),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
