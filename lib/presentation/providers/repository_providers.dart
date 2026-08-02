import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../data/datasources/local/accounting_year_local_datasource.dart';
import '../../data/repositories_impl/accounting_year_repository_impl.dart';
import '../../domain/repositories/accounting_year_repository.dart';

final accountingYearLocalDataSourceProvider = Provider<AccountingYearLocalDataSource>((ref) {
  final dbService = ref.watch(databaseProvider);
  return AccountingYearLocalDataSource(dbService.db);
});

final accountingYearRepositoryProvider = Provider<AccountingYearRepository>((ref) {
  final dataSource = ref.watch(accountingYearLocalDataSourceProvider);
  return AccountingYearRepositoryImpl(dataSource);
});
