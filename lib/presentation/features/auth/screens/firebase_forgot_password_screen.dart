import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/result.dart';
import '../controllers/firebase_auth_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

class FirebaseForgotPasswordScreen extends ConsumerStatefulWidget {
  const FirebaseForgotPasswordScreen({super.key});

  @override
  ConsumerState<FirebaseForgotPasswordScreen> createState() => _FirebaseForgotPasswordScreenState();
}

class _FirebaseForgotPasswordScreenState extends ConsumerState<FirebaseForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _translateError(String key) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'emailRequired': return loc.emailRequired;
      case 'invalidEmailFormat': return loc.invalidEmailFormat;
      case 'firebaseAuthUserNotFound': return loc.firebaseAuthUserNotFound;
      case 'passwordResetFailed': return loc.passwordResetFailed;
      default: return key;
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    final result = await ref.read(firebaseAuthControllerProvider.notifier).resetPassword(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result is Success) {
        _message = AppLocalizations.of(context)!.passwordResetSuccess;
        _isError = false;
      } else {
        _message = _translateError((result as Failure).failure.message.localize(context));
        _isError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.forgotPassword),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.passwordResetInstructions,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _resetPassword(),
                ),
                const SizedBox(height: 24),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isError ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.resetPassword),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
