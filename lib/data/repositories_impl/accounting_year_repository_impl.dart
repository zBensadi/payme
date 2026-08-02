import 'package:sqflite/sqflite.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/accounting_year.dart';
import '../../domain/repositories/accounting_year_repository.dart';
import '../datasources/local/accounting_year_local_datasource.dart';
import '../models/accounting_year_model.dart';

class AccountingYearRepositoryImpl implements AccountingYearRepository {
  final AccountingYearLocalDataSource _dataSource;

  AccountingYearRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<AccountingYear>>> getAll() async {
    try {
      final models = await _dataSource.getAll();
      return Success(models);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load accounting years: $e'));
    }
  }

  @override
  Future<Result<AccountingYear?>> getActive() async {
    try {
      final model = await _dataSource.getActive();
      return Success(model);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load active accounting year: $e'));
    }
  }

  @override
  Future<Result<AccountingYear>> create(String name) async {
    try {
      final existingYears = await _dataSource.getAll();
      final isFirst = existingYears.isEmpty;
      
      // Check for duplicates
      if (existingYears.any((y) => y.name.toLowerCase() == name.toLowerCase())) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }

      final newYear = AccountingYearModel(
        id: IdGenerator.generateUniqueId(),
        name: name,
        isActive: isFirst,
        createdAt: DateTime.now().toUtc(),
        isDirty: true,
      );

      await _dataSource.create(newYear);
      return Success(newYear);
    } catch (e) {
      // In case of SQFLite UNIQUE constraint hit simultaneously
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }
      return Failure(DatabaseFailure('Failed to create accounting year: $e'));
    }
  }

  @override
  Future<Result<void>> rename(String id, String newName) async {
    try {
      final existingYears = await _dataSource.getAll();
      if (existingYears.any((y) => y.id != id && y.name.toLowerCase() == newName.toLowerCase())) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }

      await _dataSource.rename(id, newName);
      return const Success(null);
    } catch (e) {
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }
      return Failure(DatabaseFailure('Failed to rename accounting year: $e'));
    }
  }

  @override
  Future<Result<void>> setActive(String id) async {
    try {
      await _dataSource.setActive(id);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to set active accounting year: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final year = await _dataSource.getById(id);
      if (year == null) {
        return const Failure(ValidationFailure('Accounting year not found.'));
      }

      if (year.isActive) {
        return const Failure(ValidationFailure('Cannot delete the currently active accounting year.'));
      }

      await _dataSource.delete(id);
      return const Success(null);
    } catch (e) {
      // Catch Foreign Key constraints if invoices are attached
      if (e is DatabaseException && e.toString().contains('FOREIGN KEY constraint failed')) {
        return const Failure(ValidationFailure('Cannot delete this year because it contains invoices.'));
      }
      return Failure(DatabaseFailure('Failed to delete accounting year: $e'));
    }
  }
}
