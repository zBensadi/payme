import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/error/result.dart';
import 'package:payme/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _recoveryKeyController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final key = _recoveryKeyController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (key.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.errorEmptyRecoveryKey);
      return;
    }

    if (newPass.length < 6) {
      setState(() => _error = AppLocalizations.of(context)!.errorPasswordTooShort);
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _error = AppLocalizations.of(context)!.errorPasswordsDoNotMatch);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.resetPasswordWithRecoveryKey(key, newPass);

    if (!mounted) return;

    if (result is Success<String>) {
      // The recovery succeeded and a NEW key was generated.
      // Redirect to display the new key, replacing the stack.
      context.go('/recovery-key-display', extra: result.value);
    } else {
      setState(() {
        _isLoading = false;
        _error = (result as Failure).failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.resetPassword)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Icon(Icons.key, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.recoverAccess,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.recoverAccessDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _recoveryKeyController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.recoveryKey,
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.newPassword,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.confirmNewPassword,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _resetPassword(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.resetPassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
