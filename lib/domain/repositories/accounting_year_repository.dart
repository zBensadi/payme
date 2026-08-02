import '../../core/error/result.dart';
import '../entities/accounting_year.dart';

abstract class AccountingYearRepository {
  Future<Result<List<AccountingYear>>> getAll();
  Future<Result<AccountingYear?>> getActive();
  Future<Result<AccountingYear>> create(String name);
  Future<Result<void>> rename(String id, String newName);
  Future<Result<void>> setActive(String id);
  Future<Result<void>> delete(String id);
}
