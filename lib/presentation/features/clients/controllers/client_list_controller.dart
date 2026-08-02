import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/client.dart';
import '../../../../core/error/result.dart';
import '../../../providers/repository_providers.dart';

class ClientSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final clientSearchQueryProvider = NotifierProvider<ClientSearchQuery, String>(ClientSearchQuery.new);

final clientListControllerProvider = AsyncNotifierProvider<ClientListController, List<Client>>(ClientListController.new);

class ClientListController extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() async {
    final query = ref.watch(clientSearchQueryProvider);
    return _fetchClients(query);
  }

  Future<List<Client>> _fetchClients(String query) async {
    final repo = ref.read(clientRepositoryProvider);
    final result = await repo.getAllVisible(searchQuery: query);
    
    return switch (result) {
      Success(value: final clients) => clients,
      Failure(failure: final f) => throw Exception(f.message),
    };
  }

  Future<void> softDelete(String id) async {
    final repo = ref.read(clientRepositoryProvider);
    final result = await repo.softDelete(id);

    if (result is Success) {
      ref.invalidateSelf();
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
