import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/client_visibility.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../providers/repository_providers.dart';
import 'client_list_controller.dart';

class ClientFormState {
  final String visibilityType;
  final List<String> selectedUserIds;

  const ClientFormState({
    this.visibilityType = 'everyone',
    this.selectedUserIds = const [],
  });

  ClientFormState copyWith({
    String? visibilityType,
    List<String>? selectedUserIds,
  }) {
    return ClientFormState(
      visibilityType: visibilityType ?? this.visibilityType,
      selectedUserIds: selectedUserIds ?? this.selectedUserIds,
    );
  }
}

final clientFormControllerProvider = AsyncNotifierProvider<ClientFormController, ClientFormState>(ClientFormController.new);

class ClientFormController extends AsyncNotifier<ClientFormState> {
  String? _clientId;
  List<String> _initialSelectedIds = [];

  @override
  Future<ClientFormState> build() async {
    return const ClientFormState();
  }

  Future<void> init(Client? client) async {
    _clientId = client?.id;
    if (client == null) {
      state = const AsyncData(ClientFormState());
      return;
    }

    state = const AsyncLoading();
    try {
      if (client.visibilityType == 'specific_users') {
        final repo = ref.read(clientVisibilityRepositoryProvider);
        final result = await repo.getVisibilityForClient(client.id);
        if (result is Success<List<ClientVisibility>>) {
          final ids = result.value.map((e) => e.userId).toList();
          _initialSelectedIds = List.from(ids);
          state = AsyncData(ClientFormState(visibilityType: 'specific_users', selectedUserIds: ids));
        } else {
          state = AsyncData(ClientFormState(visibilityType: 'everyone', selectedUserIds: []));
        }
      } else {
        state = const AsyncData(ClientFormState(visibilityType: 'everyone', selectedUserIds: []));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  void setVisibilityType(String type) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(visibilityType: type));
    }
  }

  void setSelectedUsers(List<String> userIds) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(selectedUserIds: userIds));
    }
  }

  Future<bool> save(Client client) async {
    final currentState = state.value;
    if (currentState == null) return false;
    
    state = const AsyncLoading();
    final repo = ref.read(clientRepositoryProvider);

    final duplicateCheck = await repo.checkDuplicate(client.name, client.phone, excludeId: client.id.isNotEmpty ? client.id : null);
    
    if (duplicateCheck is Success && (duplicateCheck as Success<bool>).value) {
      // Throwing a specific error string so the UI knows to prompt a warning
      state = AsyncData(currentState);
      throw const FormatException('duplicate_warning'); 
    }

    return _executeSave(client, currentState);
  }

  Future<bool> saveForce(Client client) async {
    final currentState = state.value;
    if (currentState == null) return false;
    
    state = const AsyncLoading();
    return _executeSave(client, currentState);
  }

  Future<bool> _executeSave(Client client, ClientFormState formState) async {
    print('[TRACE-VISIBILITY-TEST] ===== SAVE START =====');
    print('[TRACE-VISIBILITY] ClientFormController._executeSave: clientId=${client.id.isEmpty ? "NEW" : client.id}, clientName=${client.name}, visibilityType=${formState.visibilityType}, selectedUserIds=${formState.selectedUserIds}');
    final repo = ref.read(clientRepositoryProvider);
    final visibilityRepo = ref.read(clientVisibilityRepositoryProvider);
    
    Result<Client> result;
    
    final finalClient = client.copyWith(
      visibilityType: formState.visibilityType,
      updatedAt: DateTime.now().toUtc(),
      isDirty: true,
    );

    if (finalClient.id.isEmpty) {
      final newClient = finalClient.copyWith(
        id: IdGenerator.generateUniqueId(),
        createdAt: DateTime.now().toUtc(),
      );
      result = await repo.create(newClient);
    } else {
      result = await repo.update(finalClient);
    }
    print('[TRACE-VISIBILITY] ClientRepository create/update result: ${result is Success}');

    return switch (result) {
      Success(value: final savedClient) => await () async {
          // Process visibility changes
          if (formState.visibilityType == 'everyone') {
             // If previously specific, we must delete old mappings
             if (_clientId != null) {
               for (final id in _initialSelectedIds) {
                 await visibilityRepo.removeVisibility(savedClient.id, id);
               }
             }
          } else if (formState.visibilityType == 'specific_users') {
             // Compute delta
             final currentIds = formState.selectedUserIds;
             final added = currentIds.where((id) => !_initialSelectedIds.contains(id)).toList();
             final removed = _initialSelectedIds.where((id) => !currentIds.contains(id)).toList();
             
             for (final id in removed) {
               await visibilityRepo.removeVisibility(savedClient.id, id);
             }
             for (final id in added) {
               await visibilityRepo.addVisibility(ClientVisibility(clientId: savedClient.id, userId: id));
             }
          }

          state = AsyncData(formState);
          ref.invalidate(clientListControllerProvider);
          print('[TRACE-VISIBILITY-TEST] ===== SAVE END =====');
          return true;
        }(),
      Failure(failure: final f) => () {
          state = AsyncError(Exception(f.message), StackTrace.current);
          return false;
        }(),
    };
  }
}
