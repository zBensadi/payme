import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:payme/domain/repositories/client_repository.dart';
import 'package:payme/presentation/features/clients/screens/client_list_screen.dart';
import 'package:payme/presentation/providers/repository_providers.dart';

class FakeClientRepository implements ClientRepository {
  List<Client> clients = [];

  @override
  Future<Result<List<Client>>> getAllVisible({String? searchQuery}) async {
    var visible = clients.where((c) => !c.isDeleted).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      visible = visible.where((c) => c.name.toLowerCase().contains(q) || (c.phone != null && c.phone!.toLowerCase().contains(q))).toList();
    }
    return Success(visible);
  }

  @override
  Future<Result<List<Client>>> getAllDeleted({String? searchQuery}) async {
    var deleted = clients.where((c) => c.isDeleted).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      deleted = deleted.where((c) => c.name.contains(searchQuery) || (c.phone != null && c.phone!.contains(searchQuery))).toList();
    }
    return Success(deleted);
  }

  @override
  Future<Result<Client>> getById(String id) async {
    return Success(clients.firstWhere((c) => c.id == id));
  }

  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async {
    return const Success(false);
  }

  @override
  Future<Result<Client>> create(Client client) async {
    clients.add(client);
    return Success(client);
  }

  @override
  Future<Result<Client>> update(Client client) async {
    final index = clients.indexWhere((c) => c.id == client.id);
    if (index >= 0) clients[index] = client;
    return Success(client);
  }

  @override
  Future<Result<void>> softDelete(String id, {Object? txn}) async {
    final index = clients.indexWhere((c) => c.id == id);
    if (index >= 0) clients[index] = clients[index].copyWith(isDeleted: true);
    return const Success(null);
  }

  @override
  Future<Result<void>> restore(String id) async {
    final index = clients.indexWhere((c) => c.id == id);
    if (index >= 0) clients[index] = clients[index].copyWith(isDeleted: false);
    return const Success(null);
  }
}

void main() {
  testWidgets('ClientListScreen displays empty state when no clients', (WidgetTester tester) async {
    final fakeRepo = FakeClientRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: ClientListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('You haven\'t added any clients yet'), findsOneWidget);
  });

  testWidgets('ClientListScreen displays visible clients', (WidgetTester tester) async {
    final fakeRepo = FakeClientRepository();
    await fakeRepo.create(Client(id: '1', name: 'Alice', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    await fakeRepo.create(Client(id: '2', name: 'Bob', isDeleted: true, createdAt: DateTime.now(), updatedAt: DateTime.now()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: ClientListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing); // Deleted
  });
}

