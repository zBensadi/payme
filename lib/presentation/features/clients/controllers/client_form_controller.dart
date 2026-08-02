import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/client.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../providers/repository_providers.dart';
import 'client_list_controller.dart';

final clientFormControllerProvider = AsyncNotifierProvider<ClientFormController, void>(ClientFormController.new);

class ClientFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save(Client client) async {
    state = const AsyncLoading();
    final repo = ref.read(clientRepositoryProvider);

    final duplicateCheck = await repo.checkDuplicate(client.name, client.phone, excludeId: client.id.isNotEmpty ? client.id : null);
    
    if (duplicateCheck is Success && (duplicateCheck as Success<bool>).value) {
      // Throwing a specific error string so the UI knows to prompt a warning
      state = const AsyncData(null);
      throw const FormatException('duplicate_warning'); 
    }

    return _executeSave(client);
  }

  Future<bool> saveForce(Client client) async {
    state = const AsyncLoading();
    return _executeSave(client);
  }

  Future<bool> _executeSave(Client client) async {
    final repo = ref.read(clientRepositoryProvider);
    Result<Client> result;

    if (client.id.isEmpty) {
      final newClient = client.copyWith(
        id: IdGenerator.generateUniqueId(),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        isDirty: true,
      );
      result = await repo.create(newClient);
    } else {
      final updatedClient = client.copyWith(
        updatedAt: DateTime.now().toUtc(),
        isDirty: true,
      );
      result = await repo.update(updatedClient);
    }

    return switch (result) {
      Success() => () {
          state = const AsyncData(null);
          ref.invalidate(clientListControllerProvider);
          return true;
        }(),
      Failure(failure: final f) => () {
          state = AsyncError(Exception(f.message), StackTrace.current);
          return false;
        }(),
    };
  }
}
