import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/result.dart';
import '../controllers/firebase_auth_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

class FirebaseLoginScreen extends ConsumerStatefulWidget {
  const FirebaseLoginScreen({super.key});

  @override
  ConsumerState<FirebaseLoginScreen> createState() => _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends ConsumerState<FirebaseLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _translateError(String key) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'emailRequired': return loc.emailRequired;
      case 'passwordRequired': return loc.passwordRequired;
      case 'invalidEmailFormat': return loc.invalidEmailFormat;
      case 'firebaseAuthInvalidCredentials': return loc.firebaseAuthInvalidCredentials;
      case 'firebaseAuthUserNotFound': return loc.firebaseAuthUserNotFound;
      default: return key;
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(firebaseAuthControllerProvider.notifier).login(email, password);

    if (!mounted) return;

    if (result is Failure) {
      setState(() {
        _isLoading = false;
        _error = _translateError(result.failure.message.localize(context));
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cloud_circle, size: 64, color: Colors.blue),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.enterPasswordToContinue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(AppLocalizations.of(context)!.login),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/firebase-forgot-password'),
                    child: Text(AppLocalizations.of(context)!.forgotPassword),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
