import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/client.dart';
import '../../../../core/error/result.dart';
import '../../../providers/repository_providers.dart';
import 'client_list_controller.dart';

class DeletedClientSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final deletedClientSearchQueryProvider = NotifierProvider<DeletedClientSearchQuery, String>(DeletedClientSearchQuery.new);

final deletedClientsControllerProvider = AsyncNotifierProvider<DeletedClientsController, List<Client>>(DeletedClientsController.new);

class DeletedClientsController extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() async {
    final query = ref.watch(deletedClientSearchQueryProvider);
    return _fetchDeletedClients(query);
  }

  Future<List<Client>> _fetchDeletedClients(String query) async {
    final repo = ref.read(clientRepositoryProvider);
    final result = await repo.getAllDeleted(searchQuery: query);
    
    return switch (result) {
      Success(value: final clients) => clients,
      Failure(failure: final f) => throw Exception(f.message),
    };
  }

  Future<void> restore(String id) async {
    final repo = ref.read(clientRepositoryProvider);
    final result = await repo.restore(id);

    if (result is Success) {
      ref.invalidateSelf();
      ref.invalidate(clientListControllerProvider);
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }
}
