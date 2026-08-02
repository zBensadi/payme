import 'package:flutter/material.dart';

class FatalAuthErrorScreen extends StatelessWidget {
  const FatalAuthErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Authentication Corrupted',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The application has detected existing business data, but the administrator credentials could not be found or are corrupted.\n\n'
                  'To protect your data from unauthorized takeover, creating a new administrator account is blocked.\n\n'
                  'Please restore the database from a known good backup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
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
