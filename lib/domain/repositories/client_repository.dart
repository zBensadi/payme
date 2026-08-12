import '../../core/error/result.dart';
import '../entities/client.dart';
import '../entities/client_visibility_context.dart';

abstract class ClientRepository {
  Future<Result<List<Client>>> getAllVisible({String? searchQuery, ClientVisibilityContext? visibilityContext});
  Future<Result<List<Client>>> getAllDeleted({String? searchQuery});
  Future<Result<Client>> getById(String id);
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId});
  Future<Result<Client>> create(Client client);
  Future<Result<Client>> update(Client client);
  Future<Result<void>> softDelete(String id, {Object? txn});
  Future<Result<void>> restore(String id);
}
