import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/accounting_year.dart';
import '../../../../core/error/result.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/active_year_provider.dart';

final accountingYearControllerProvider =
    AsyncNotifierProvider<AccountingYearController, List<AccountingYear>>(
        AccountingYearController.new);

class AccountingYearController extends AsyncNotifier<List<AccountingYear>> {
  @override
  Future<List<AccountingYear>> build() async {
    return _fetchYears();
  }

  Future<List<AccountingYear>> _fetchYears() async {
    final repo = ref.read(accountingYearRepositoryProvider);
    final result = await repo.getAll();
    
    return switch (result) {
      Success(value: final years) => years,
      Failure(failure: final f) => throw Exception(f.message),
    };
  }

  Future<void> create(String name) async {
    final repo = ref.read(accountingYearRepositoryProvider);
    final result = await repo.create(name);
    
    if (result is Success) {
      ref.invalidateSelf();
      ref.invalidate(activeYearProvider);
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }

  Future<void> rename(String id, String newName) async {
    final repo = ref.read(accountingYearRepositoryProvider);
    final result = await repo.rename(id, newName);

    if (result is Success) {
      ref.invalidateSelf();
      ref.invalidate(activeYearProvider);
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }

  Future<void> setActive(String id) async {
    final repo = ref.read(accountingYearRepositoryProvider);
    final result = await repo.setActive(id);

    if (result is Success) {
      ref.invalidateSelf();
      ref.invalidate(activeYearProvider);
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }

  Future<void> delete(String id) async {
    final repo = ref.read(accountingYearRepositoryProvider);
    final result = await repo.delete(id);

    if (result is Success) {
      ref.invalidateSelf();
      // No need to invalidate activeYearProvider because we can't delete the active year
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }
}
