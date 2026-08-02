import 'package:sqflite/sqflite.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/local/client_local_datasource.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource _dataSource;

  ClientRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Client>>> getAllVisible({String? searchQuery}) async {
    try {
      final models = await _dataSource.getAllVisible(searchQuery: searchQuery);
      return Success(models);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load clients: $e'));
    }
  }

  @override
  Future<Result<List<Client>>> getAllDeleted({String? searchQuery}) async {
    try {
      final models = await _dataSource.getAllDeleted(searchQuery: searchQuery);
      return Success(models);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load deleted clients: $e'));
    }
  }

  @override
  Future<Result<Client>> getById(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return const Failure(ValidationFailure('Client not found.'));
      }
      return Success(model);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load client: $e'));
    }
  }

  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async {
    try {
      final matches = await _dataSource.getByNameAndPhone(name, phone);
      if (excludeId != null) {
        return Success(matches.any((m) => m.id != excludeId));
      }
      return Success(matches.isNotEmpty);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to check for duplicate clients: $e'));
    }
  }

  @override
  Future<Result<Client>> create(Client client) async {
    try {
      final model = ClientModel.fromEntity(client);
      await _dataSource.create(model);
      return Success(client);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to create client: $e'));
    }
  }

  @override
  Future<Result<Client>> update(Client client) async {
    try {
      final model = ClientModel.fromEntity(client);
      await _dataSource.update(model);
      return Success(client);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update client: $e'));
    }
  }

  @override
  Future<Result<void>> softDelete(String id) async {
    try {
      await _dataSource.softDelete(id);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete client: $e'));
    }
  }

  @override
  Future<Result<void>> restore(String id) async {
    try {
      await _dataSource.restore(id);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to restore client: $e'));
    }
  }
}
