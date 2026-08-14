import sys

file_path = "test/presentation/features/clients/controllers/client_form_controller_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_priority.dart';
import 'package:payme/core/sync/sync_result.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:payme/domain/entities/client_visibility.dart';
import 'package:payme/domain/repositories/client_repository.dart';
import 'package:payme/domain/repositories/client_visibility_repository.dart';
import 'package:payme/presentation/features/clients/controllers/client_form_controller.dart';
import 'package:payme/presentation/providers/repository_providers.dart';

class MockClientRepository implements ClientRepository {
  @override
  SyncDomain get syncDomain => SyncDomain.clients;
  @override
  SyncPriority get syncPriority => SyncPriority.medium;
  @override
  Future<SyncResult> pullChanges(String b, DateTime? d) async => const SyncResult(downloaded: 0);
  @override
  Future<SyncResult> pushChanges(String b) async => const SyncResult(uploaded: 0);

  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async => const Success(false);
  
  @override
  Future<Result<Client>> create(Client c) async => Success(c);
  
  @override
  Future<Result<Client>> update(Client c) async => Success(c);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<Client?>> getClient(String id) async => const Success(null);
  
  @override
  Future<Result<List<Client>>> getClients() async => const Success([]);

  @override
  Stream<void> get onDidChange => const Stream.empty();
}

class MockClientVisibilityRepository implements ClientVisibilityRepository {
  List<ClientVisibility> mockVisibility = [];
  List<String> removedUsers = [];
  List<String> addedUsers = [];
  int getVisibilityCalls = 0;

  @override
  SyncDomain get syncDomain => SyncDomain.clientVisibility;
  @override
  SyncPriority get syncPriority => SyncPriority.medium;
  @override
  Future<SyncResult> pullChanges(String b, DateTime? d) async => const SyncResult(downloaded: 0);
  @override
  Future<SyncResult> pushChanges(String b) async => const SyncResult(uploaded: 0);

  @override
  Future<Result<List<ClientVisibility>>> getVisibilityForClient(String clientId) async {
    getVisibilityCalls++;
    return Success(mockVisibility);
  }

  @override
  Future<Result<void>> addVisibility(ClientVisibility visibility) async {
    addedUsers.add(visibility.userId);
    return const Success(null);
  }

  @override
  Future<Result<void>> removeVisibility(String clientId, String userId) async {
    removedUsers.add(userId);
    return const Success(null);
  }
}

void main() {
  late MockClientRepository mockClientRepo;
  late MockClientVisibilityRepository mockVisibilityRepo;
  late ProviderContainer container;

  setUp(() {
    mockClientRepo = MockClientRepository();
    mockVisibilityRepo = MockClientVisibilityRepository();

    container = ProviderContainer(
      overrides: [
        clientRepositoryProvider.overrideWithValue(mockClientRepo),
        clientVisibilityRepositoryProvider.overrideWithValue(mockVisibilityRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ClientFormController Tests', () {
    final mockClient = Client(
      id: 'client_1',
      name: 'Client 1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      visibilityType: 'specific_users',
    );

    test('init() populates everyone if visibilityType is everyone', () async {
      final clientEveryone = mockClient.copyWith(visibilityType: 'everyone');
      final controller = container.read(clientFormControllerProvider.notifier);
      
      await controller.init(clientEveryone);
      final state = container.read(clientFormControllerProvider).value!;
      
      expect(state.visibilityType, 'everyone');
      expect(state.selectedUserIds, isEmpty);
      expect(mockVisibilityRepo.getVisibilityCalls, 0);
    });

    test('init() fetches specific users if visibilityType is specific_users', () async {
      mockVisibilityRepo.mockVisibility = [
        const ClientVisibility(clientId: 'client_1', userId: 'user_1'),
        const ClientVisibility(clientId: 'client_1', userId: 'user_2'),
      ];

      final controller = container.read(clientFormControllerProvider.notifier);
      
      await controller.init(mockClient);
      final state = container.read(clientFormControllerProvider).value!;
      
      expect(state.visibilityType, 'specific_users');
      expect(state.selectedUserIds, containsAll(['user_1', 'user_2']));
      expect(mockVisibilityRepo.getVisibilityCalls, 1);
    });

    test('save() updates visibility mappings properly', () async {
      mockVisibilityRepo.mockVisibility = [
        const ClientVisibility(clientId: 'client_1', userId: 'user_1'), // Existing
      ];

      final controller = container.read(clientFormControllerProvider.notifier);
      
      await controller.init(mockClient);
      
      // Change visibility selection: Keep user_1 implicitly by removing it and adding user_2
      controller.setSelectedUsers(['user_2']);
      
      await controller.save(mockClient);
      
      // Verify the delta logic
      expect(mockVisibilityRepo.removedUsers, ['user_1']);
      expect(mockVisibilityRepo.addedUsers, ['user_2']);
    });
  });
}
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(replacement)
