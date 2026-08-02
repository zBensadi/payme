import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../data/datasources/local/accounting_year_local_datasource.dart';
import '../../data/repositories_impl/accounting_year_repository_impl.dart';
import '../../domain/repositories/accounting_year_repository.dart';
import '../../data/datasources/local/client_local_datasource.dart';
import '../../data/repositories_impl/client_repository_impl.dart';
import '../../domain/repositories/client_repository.dart';

// Accounting Year Providers

final accountingYearLocalDataSourceProvider = Provider<AccountingYearLocalDataSource>((ref) {
  final dbService = ref.watch(databaseProvider);
  return AccountingYearLocalDataSource(dbService.db);
});

final accountingYearRepositoryProvider = Provider<AccountingYearRepository>((ref) {
  final dataSource = ref.watch(accountingYearLocalDataSourceProvider);
  return AccountingYearRepositoryImpl(dataSource);
});

// Client Providers
final clientLocalDataSourceProvider = Provider<ClientLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  if (!dbState.db.isOpen) {
    throw Exception('Database not initialized');
  }
  return ClientLocalDataSource(dbState.db);
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final dataSource = ref.watch(clientLocalDataSourceProvider);
  return ClientRepositoryImpl(dataSource);
});
