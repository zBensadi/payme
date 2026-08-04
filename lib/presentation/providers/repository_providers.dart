import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/csv_generation_service.dart';
import '../../core/database/database_provider.dart';
import '../../services/pdf_generation_service.dart';
import '../../services/backup_service.dart';
import '../../data/repositories_impl/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../data/datasources/local/accounting_year_local_datasource.dart';
import '../../data/repositories_impl/accounting_year_repository_impl.dart';
import '../../domain/repositories/accounting_year_repository.dart';
import '../../data/datasources/local/client_local_datasource.dart';
import '../../data/datasources/local/invoice_local_datasource.dart';
import '../../data/datasources/local/payment_local_datasource.dart';
import '../../data/datasources/local/settings_local_datasource.dart';
import '../../data/datasources/file/attachment_file_datasource.dart';
import '../../data/datasources/file/logo_file_datasource.dart';

import '../../data/repositories_impl/client_repository_impl.dart';
import '../../data/repositories_impl/invoice_repository_impl.dart';
import '../../data/repositories_impl/payment_repository_impl.dart';
import '../../data/repositories_impl/settings_repository_impl.dart';

import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/settings_repository.dart';

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


final pdfGenerationServiceProvider = Provider<PdfGenerationService>((ref) {
  return PdfGenerationService();
});

final csvGenerationServiceProvider = Provider<CsvGenerationService>((ref) {
  return CsvGenerationService(
    ref.read(clientRepositoryProvider),
    ref.read(invoiceRepositoryProvider),
  );
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(backupRepositoryProvider),
    ref.watch(databaseProvider),
  );
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final dataSource = ref.watch(clientLocalDataSourceProvider);
  return ClientRepositoryImpl(dataSource);
});

// Invoice Providers
final invoiceLocalDataSourceProvider = Provider<InvoiceLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  if (!dbState.db.isOpen) {
    throw Exception('Database not initialized');
  }
  return InvoiceLocalDataSource(dbState);
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final dataSource = ref.watch(invoiceLocalDataSourceProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final fileDataSource = ref.watch(attachmentFileDataSourceProvider);
  return InvoiceRepositoryImpl(dataSource, paymentRepo, fileDataSource);
});

// Payment Providers
final paymentLocalDataSourceProvider = Provider<PaymentLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  if (!dbState.db.isOpen) {
    throw Exception('Database not initialized');
  }
  return PaymentLocalDataSource(dbState);
});

final attachmentFileDataSourceProvider = Provider<AttachmentFileDataSource>((ref) {
  return AttachmentFileDataSource();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final localDataSource = ref.watch(paymentLocalDataSourceProvider);
  final fileDataSource = ref.watch(attachmentFileDataSourceProvider);
  return PaymentRepositoryImpl(localDataSource, fileDataSource);
});

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  return SettingsLocalDataSource(dbState);
});

final logoFileDataSourceProvider = Provider<LogoFileDataSource>((ref) {
  return LogoFileDataSource();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final settingsLocal = ref.watch(settingsLocalDataSourceProvider);
  final logoFile = ref.watch(logoFileDataSourceProvider);

  return SettingsRepositoryImpl(settingsLocal, logoFile);
});
