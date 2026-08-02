import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../error/result.dart';

class ReauthGuard {
  /// Prompts the user for their password before proceeding.
  /// Returns [true] if authenticated successfully, [false] if cancelled or failed.
  static Future<bool> requestReauth(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReauthDialog(authService: authService),
    );
    
    return result == true;
  }
}

class _ReauthDialog extends StatefulWidget {
  final AuthService authService;

  const _ReauthDialog({required this.authService});

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await widget.authService.login(_passwordController.text);
    
    if (!mounted) return;

    if (result is Success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Incorrect password.';
        // We do not aggressively clear the field, so user can correct typos.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Authentication Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please enter your password to perform this action.'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _verify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verify,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Text('Verify'),
        ),
      ],
    );
  }
}
