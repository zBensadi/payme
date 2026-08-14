import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/accounting_year.dart';
import '../../core/error/result.dart';
import 'repository_providers.dart';
import '../utils/riverpod_invalidation_helper.dart';

final activeYearProvider = FutureProvider<AccountingYear?>((ref) async {
  // Use the internal repository to bypass feature-level authorization guards.
  // The active year is a foundational application context required for dashboard
  // and other queries. Lack of 'accounting_years.view' permission should not
  // block the application from loading its foundational context.
  final repo = ref.watch(internalAccountingYearRepositoryProvider);
  ref.invalidateOnRepositoryChange(repo);
  final result = await repo.getActive();
  
  return switch (result) {
    Success(value: final year) => year,
    Failure() => null,
  };
});
