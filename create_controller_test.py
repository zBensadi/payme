import sys

file_path = "test/presentation/features/clients/controllers/client_form_controller_test.dart"
content = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:payme/domain/entities/client_visibility.dart';
import 'package:payme/domain/repositories/client_repository.dart';
import 'package:payme/domain/repositories/client_visibility_repository.dart';
import 'package:payme/presentation/features/clients/controllers/client_form_controller.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockClientRepository extends Mock implements ClientRepository {}
class MockClientVisibilityRepository extends Mock implements ClientVisibilityRepository {}

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
      verifyNever(() => mockVisibilityRepo.getVisibilityForClient(any()));
    });

    test('init() fetches specific users if visibilityType is specific_users', () async {
      when(() => mockVisibilityRepo.getVisibilityForClient('client_1'))
          .thenAnswer((_) async => const Success([
                ClientVisibility(clientId: 'client_1', userId: 'user_1'),
                ClientVisibility(clientId: 'client_1', userId: 'user_2'),
              ]));

      final controller = container.read(clientFormControllerProvider.notifier);
      
      await controller.init(mockClient);
      final state = container.read(clientFormControllerProvider).value!;
      
      expect(state.visibilityType, 'specific_users');
      expect(state.selectedUserIds, containsAll(['user_1', 'user_2']));
      verify(() => mockVisibilityRepo.getVisibilityForClient('client_1')).called(1);
    });

    test('save() updates visibility mappings properly', () async {
      when(() => mockClientRepo.checkDuplicate(any(), any(), excludeId: any(named: 'excludeId')))
          .thenAnswer((_) async => const Success(false));
      
      when(() => mockClientRepo.update(any()))
          .thenAnswer((_) async => Success(mockClient));

      when(() => mockVisibilityRepo.getVisibilityForClient('client_1'))
          .thenAnswer((_) async => const Success([
                ClientVisibility(clientId: 'client_1', userId: 'user_1'), // Existing
              ]));
              
      when(() => mockVisibilityRepo.removeVisibility(any(), any()))
          .thenAnswer((_) async => const Success(null));
          
      when(() => mockVisibilityRepo.addVisibility(any()))
          .thenAnswer((_) async => const Success(null));

      final controller = container.read(clientFormControllerProvider.notifier);
      
      await controller.init(mockClient);
      
      // Change visibility selection: Keep user_1 (implicitly, let's remove it and add user_2)
      controller.setSelectedUsers(['user_2']);
      
      await controller.save(mockClient);
      
      // Verify the delta logic
      verify(() => mockVisibilityRepo.removeVisibility('client_1', 'user_1')).called(1);
      
      final captured = verify(() => mockVisibilityRepo.addVisibility(captureAny())).captured;
      final addedVisibility = captured.first as ClientVisibility;
      expect(addedVisibility.userId, 'user_2');
    });
  });
}
"""

import os
os.makedirs("test/presentation/features/clients/controllers", exist_ok=True)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
