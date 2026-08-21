import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payme/l10n/app_localizations.dart';

import '../../../../core/error/result.dart';
import '../controllers/bootstrap_controller.dart';

class FirebaseBootstrapScreen extends ConsumerStatefulWidget {
  const FirebaseBootstrapScreen({super.key});

  @override
  ConsumerState<FirebaseBootstrapScreen> createState() =>
      _FirebaseBootstrapScreenState();
}

class _FirebaseBootstrapScreenState
    extends ConsumerState<FirebaseBootstrapScreen> {
  final _businessNameController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingSession = true;
  bool _isCorrupted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkSession();
    });
  }

  Future<void> _checkSession() async {
    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] ENTER _checkSession()');
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] currentUser=${user?.uid ?? 'null'}');
    if (user == null) {
      debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] user=null — setState(_isCheckingSession=false)');
      if (mounted) {
        setState(() => _isCheckingSession = false);
        debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] setState done — _isCheckingSession=false');
      }
      return;
    }

    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] BEFORE checkAndRecoverSession(uid=${user.uid})');
    final result = await ref.read(bootstrapControllerProvider.notifier).checkAndRecoverSession(
      uid: user.uid,
      email: user.email ?? '',
    );
    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] AFTER  checkAndRecoverSession() → ${result.runtimeType}');

    if (!mounted) {
      debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] widget unmounted after checkAndRecoverSession — returning');
      return;
    }

    if (result is Success && (result as Success<bool>).value == true) {
      // Session recovered. currentUserProvider has been invalidated.
      // GoRouter will redirect automatically.
      debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] session recovered (Success=true) — no setState needed, GoRouter will navigate');
      return;
    }

    // Genuine new user (or error). Show bootstrap form.
    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] BEFORE setState(_isCheckingSession=false isCorrupted=${result is Failure})');
    setState(() {
      _isCheckingSession = false;
      if (result is Failure) {
        _error = (result as Failure).failure.message.localize(context);
        _isCorrupted = true;
      }
    });
    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] AFTER  setState — _isCheckingSession=$_isCheckingSession _isCorrupted=$_isCorrupted _error=$_error');
  }

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

    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] BEFORE ref.read(bootstrapControllerProvider.notifier).bootstrap()');
    final result = await ref.read(bootstrapControllerProvider.notifier).bootstrap(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          businessName: businessName,
        );
    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] AFTER  bootstrap() returns → ${result.runtimeType}');

    if (!mounted) {
      debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] widget unmounted after bootstrap() — returning');
      return;
    }

    if (result is Failure) {
      debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] bootstrap failed → setState(isLoading=false)');
      setState(() {
        _isLoading = false;
        _error = result.failure.message.localize(context);
      });
    } else {
      debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] bootstrap succeeded → waiting for router to navigate (no manual navigation)');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] build() called — _isCheckingSession=$_isCheckingSession _isCorrupted=$_isCorrupted _isLoading=$_isLoading _error=$_error');
    if (_isCheckingSession) {
      debugPrint('[BSSCREEN][${DateTime.now().toIso8601String()}] build() returning CircularProgressIndicator (isCheckingSession=true)');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isCorrupted) {
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Account Data Error',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your account is in an inconsistent state and cannot be recovered automatically.\n\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isCorrupted = false;
                        _isCheckingSession = true;
                        _error = null;
                      });
                      _checkSession();
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
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
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
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
