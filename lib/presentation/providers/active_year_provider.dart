import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/accounting_year.dart';
import '../../core/error/result.dart';
import 'repository_providers.dart';

final activeYearProvider = FutureProvider<AccountingYear?>((ref) async {
  final repo = ref.watch(accountingYearRepositoryProvider);
  final result = await repo.getActive();
  
  return switch (result) {
    Success(value: final year) => year,
    Failure() => null,
  };
});
