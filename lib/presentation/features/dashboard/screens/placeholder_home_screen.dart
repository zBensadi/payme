import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/database_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../providers/active_year_provider.dart';

class PlaceholderHomeScreen extends ConsumerWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(databaseProvider);
    final activeYearAsync = ref.watch(activeYearProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayMe Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: 'Lock',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('PayMe', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Accounting Years'),
              onTap: () {
                Navigator.pop(context);
                context.push('/accounting-years');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PayMe', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Placeholder Dashboard'),
            const SizedBox(height: 32),
            if (dbService.db.isOpen)
              const Text('Database initialized ✅', style: TextStyle(color: Colors.green))
            else
              const Text('Database not ready', style: TextStyle(color: Colors.orange)),
            const SizedBox(height: 32),
            activeYearAsync.when(
              data: (year) {
                if (year == null) {
                  return Column(
                    children: [
                      const Text('No Active Accounting Year', style: TextStyle(color: Colors.red, fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/accounting-years'),
                        child: const Text('Setup Accounting Year'),
                      ),
                    ],
                  );
                }
                return Text(
                  'Active Year: ${year.name}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
