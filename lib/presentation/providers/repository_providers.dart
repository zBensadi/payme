import 'dart:ui';
import '../../l10n/app_localizations.dart';
import 'locale_controller.dart';
import '../../core/pdf/app_pdf_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_trigger_provider.dart';
import '../../core/sync/conflict_resolver.dart';
import '../../domain/entities/business_settings.dart';
import '../../domain/entities/accounting_year.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../../data/datasources/remote/settings_remote_datasource.dart';
import '../../data/datasources/remote/client_remote_datasource.dart';
import '../../data/datasources/remote/invoice_remote_datasource.dart';
import '../../data/datasources/remote/payment_remote_datasource.dart';
import '../../services/csv_generation_service.dart';
import '../../core/database/database_provider.dart';
import '../../services/pdf_generation_service.dart';
import '../../services/backup_service.dart';
import '../../data/repositories_impl/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../data/datasources/local/accounting_year_local_datasource.dart';
import '../../data/repositories_impl/accounting_year_repository_impl.dart';
import '../../domain/repositories/accounting_year_repository.dart';
import '../../data/datasources/remote/accounting_year_remote_datasource.dart';
import '../../data/datasources/local/client_local_datasource.dart';
import '../../data/datasources/local/invoice_local_datasource.dart';
import '../../data/datasources/local/payment_local_datasource.dart';
import '../../data/datasources/local/settings_local_datasource.dart';
import '../../data/datasources/file/attachment_file_datasource.dart';
import '../../data/datasources/file/logo_file_datasource.dart';
import '../../core/sync/accounting_year_conflict_resolver.dart';

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

final accountingYearRemoteDataSourceProvider = Provider<AccountingYearRemoteDataSource>((ref) {
  return AccountingYearRemoteDataSource();
});

final accountingYearConflictResolverProvider = Provider<ConflictResolver<AccountingYear>>((ref) {
  return AccountingYearConflictResolver();
});

final accountingYearRepositoryProvider = Provider<AccountingYearRepository>((ref) {
  final localDataSource = ref.watch(accountingYearLocalDataSourceProvider);
  final remoteDataSource = ref.watch(accountingYearRemoteDataSourceProvider);
  final conflictResolver = ref.watch(accountingYearConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  final repo = AccountingYearRepositoryImpl(localDataSource, remoteDataSource, conflictResolver, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
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
  final String localeCode = ref.watch(localeControllerProvider)?.languageCode ?? 'en';
  final appLoc = lookupAppLocalizations(Locale(localeCode));
  final pdfLoc = AppPdfLocalizations(appLoc);
  return PdfGenerationService(pdfLoc);
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

final clientRemoteDataSourceProvider = Provider<ClientRemoteDataSource>((ref) {
  return ClientRemoteDataSource();
});

final clientConflictResolverProvider = Provider<ConflictResolver<Client>>((ref) {
  return DefaultConflictResolver<Client>();
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final localDataSource = ref.watch(clientLocalDataSourceProvider);
  final remoteDataSource = ref.watch(clientRemoteDataSourceProvider);
  final conflictResolver = ref.watch(clientConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  final repo = ClientRepositoryImpl(localDataSource, remoteDataSource, conflictResolver, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
});

// Invoice Providers
final invoiceLocalDataSourceProvider = Provider<InvoiceLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  if (!dbState.db.isOpen) {
    throw Exception('Database not initialized');
  }
  return InvoiceLocalDataSource(dbState);
});

final invoiceRemoteDataSourceProvider = Provider<InvoiceRemoteDataSource>((ref) {
  return InvoiceRemoteDataSource();
});

final invoiceConflictResolverProvider = Provider<ConflictResolver<Invoice>>((ref) {
  return DefaultConflictResolver<Invoice>();
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final dataSource = ref.watch(invoiceLocalDataSourceProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final fileDataSource = ref.watch(attachmentFileDataSourceProvider);
  final remoteDataSource = ref.watch(invoiceRemoteDataSourceProvider);
  final conflictResolver = ref.watch(invoiceConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  
  final repo = InvoiceRepositoryImpl(
    dataSource, 
    paymentRepo, 
    fileDataSource, 
    remoteDataSource, 
    conflictResolver, 
    syncTrigger,
  );
  ref.onDispose(() => repo.dispose());
  return repo;
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

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSource();
});

final paymentConflictResolverProvider = Provider<ConflictResolver<Payment>>((ref) {
  return DefaultConflictResolver<Payment>();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final localDataSource = ref.watch(paymentLocalDataSourceProvider);
  final fileDataSource = ref.watch(attachmentFileDataSourceProvider);
  final remoteDataSource = ref.watch(paymentRemoteDataSourceProvider);
  final conflictResolver = ref.watch(paymentConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  final repo = PaymentRepositoryImpl(
    localDataSource, 
    fileDataSource,
    remoteDataSource,
    conflictResolver,
    syncTrigger,
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  return SettingsLocalDataSource(dbState);
});

final logoFileDataSourceProvider = Provider<LogoFileDataSource>((ref) {
  return LogoFileDataSource();
});

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>((ref) {
  return SettingsRemoteDataSource();
});

final settingsConflictResolverProvider = Provider<ConflictResolver<BusinessSettings>>((ref) {
  return DefaultConflictResolver<BusinessSettings>();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final settingsLocal = ref.watch(settingsLocalDataSourceProvider);
  final settingsRemote = ref.watch(settingsRemoteDataSourceProvider);
  final logoFile = ref.watch(logoFileDataSourceProvider);
  final conflictResolver = ref.watch(settingsConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);

  final repo = SettingsRepositoryImpl(settingsLocal, settingsRemote, logoFile, conflictResolver, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
});
