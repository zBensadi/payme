import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../l10n/app_localizations.dart';
import 'locale_controller.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/role_repository.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/datasources/local/role_local_datasource.dart';
import '../../data/datasources/remote/user_remote_datasource.dart';
import '../../data/datasources/remote/role_remote_datasource.dart';
import '../../data/repositories_impl/user_repository_impl.dart';
import '../../data/repositories_impl/role_repository_impl.dart';

import '../../domain/entities/accounting_year.dart';
import '../../core/pdf/app_pdf_localizations.dart';
import '../../data/datasources/remote/client_remote_datasource.dart';
import '../../data/repositories_impl/secured/secured_client_repository.dart';
import '../../data/repositories_impl/secured/secured_client_visibility_repository.dart';
import '../../data/repositories_impl/secured/secured_invoice_repository.dart';
import '../../data/repositories_impl/secured/secured_payment_repository.dart';
import '../../data/repositories_impl/secured/secured_settings_repository.dart';
import '../../data/repositories_impl/secured/secured_user_repository.dart';
import '../../data/repositories_impl/secured/secured_role_repository.dart';
import '../../data/repositories_impl/secured/secured_accounting_year_repository.dart';
import 'sync_trigger_provider.dart';

import '../features/auth/controllers/current_user_controller.dart';
import 'permission_service_provider.dart';
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

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/local/client_visibility_local_datasource.dart';
import '../../data/datasources/remote/client_visibility_remote_datasource.dart';
import '../../data/repositories_impl/client_visibility_repository_impl.dart';
import '../../domain/repositories/client_visibility_repository.dart';
import '../../data/repositories_impl/secured/secured_client_visibility_repository.dart';
import '../../data/repositories_impl/client_repository_impl.dart';
import '../../data/repositories_impl/invoice_repository_impl.dart';
import '../../data/repositories_impl/payment_repository_impl.dart';
import '../../data/repositories_impl/settings_repository_impl.dart';

import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/entities/business_settings.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../../core/sync/conflict_resolver.dart';

import '../../data/datasources/remote/settings_remote_datasource.dart';
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

final internalAccountingYearRepositoryProvider = Provider<AccountingYearRepositoryImpl>((ref) {
  final localDataSource = ref.watch(accountingYearLocalDataSourceProvider);
  final invoiceDataSource = ref.watch(invoiceLocalDataSourceProvider);
  final remoteDataSource = ref.watch(accountingYearRemoteDataSourceProvider);
  final conflictResolver = ref.watch(accountingYearConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  final repo = AccountingYearRepositoryImpl(localDataSource, invoiceDataSource, remoteDataSource, conflictResolver, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final accountingYearRepositoryProvider = Provider<AccountingYearRepository>((ref) {
  final internal = ref.watch(internalAccountingYearRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredAccountingYearRepository(internal, permissionService, currentUser);
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

final internalClientRepositoryProvider = Provider<ClientRepositoryImpl>((ref) {
  final localDataSource = ref.watch(clientLocalDataSourceProvider);
  final remoteDataSource = ref.watch(clientRemoteDataSourceProvider);
  final conflictResolver = ref.watch(clientConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  final repo = ClientRepositoryImpl(localDataSource, remoteDataSource, conflictResolver, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final inner = ref.watch(internalClientRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredClientRepository(inner, permissionService, currentUser);
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

final internalInvoiceRepositoryProvider = Provider<InvoiceRepositoryImpl>((ref) {
  final dataSource = ref.watch(invoiceLocalDataSourceProvider);
  final paymentRepo = ref.watch(internalPaymentRepositoryProvider);
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

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final inner = ref.watch(internalInvoiceRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredInvoiceRepository(inner, permissionService, currentUser);
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

final internalPaymentRepositoryProvider = Provider<PaymentRepositoryImpl>((ref) {
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

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final inner = ref.watch(internalPaymentRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredPaymentRepository(inner, permissionService, currentUser);
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

final internalSettingsRepositoryProvider = Provider<SettingsRepositoryImpl>((ref) {
  final settingsLocal = ref.watch(settingsLocalDataSourceProvider);
  final settingsRemote = ref.watch(settingsRemoteDataSourceProvider);
  final logoFile = ref.watch(logoFileDataSourceProvider);
  final conflictResolver = ref.watch(settingsConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);

  final repo = SettingsRepositoryImpl(settingsLocal, settingsRemote, logoFile, conflictResolver, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final inner = ref.watch(internalSettingsRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredSettingsRepository(inner, permissionService, currentUser);
});

// Role Providers
final roleLocalDataSourceProvider = Provider<RoleLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  if (!dbState.db.isOpen) throw Exception('Database not initialized');
  return RoleLocalDataSource(dbState.db);
});

final roleRemoteDataSourceProvider = Provider<RoleRemoteDataSource>((ref) {
  return RoleRemoteDataSource();
});

final roleConflictResolverProvider = Provider<ConflictResolver<UserRole>>((ref) {
  return DefaultConflictResolver<UserRole>();
});

final internalRoleRepositoryProvider = Provider<RoleRepositoryImpl>((ref) {
  final local = ref.watch(roleLocalDataSourceProvider);
  final remote = ref.watch(roleRemoteDataSourceProvider);
  final conflict = ref.watch(roleConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  
  final repo = RoleRepositoryImpl(local, remote, conflict, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final inner = ref.watch(internalRoleRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  final userRepo = ref.watch(internalUserRepositoryProvider);
  return SecuredRoleRepository(inner, permissionService, currentUser, userRepo);
});

// User Providers
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  if (!dbState.db.isOpen) throw Exception('Database not initialized');
  return UserLocalDataSource(dbState.db);
});

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource();
});

final userConflictResolverProvider = Provider<ConflictResolver<AppUser>>((ref) {
  return DefaultConflictResolver<AppUser>();
});

final internalUserRepositoryProvider = Provider<UserRepositoryImpl>((ref) {
  final local = ref.watch(userLocalDataSourceProvider);
  final remote = ref.watch(userRemoteDataSourceProvider);
  final conflict = ref.watch(userConflictResolverProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  
  final repo = UserRepositoryImpl(local, remote, conflict, syncTrigger);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final inner = ref.watch(internalUserRepositoryProvider);
  final roleRepo = ref.watch(internalRoleRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredUserRepository(inner, roleRepo, permissionService, currentUser);
});

// Client Visibility Providers
final clientVisibilityLocalDataSourceProvider = Provider<ClientVisibilityLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  return ClientVisibilityLocalDataSource(dbState);
});

final clientVisibilityRemoteDataSourceProvider = Provider<ClientVisibilityRemoteDataSource>((ref) {
  return ClientVisibilityRemoteDataSource(FirebaseFirestore.instance);
});

final internalClientVisibilityRepositoryProvider = Provider<ClientVisibilityRepositoryImpl>((ref) {
  final local = ref.watch(clientVisibilityLocalDataSourceProvider);
  final remote = ref.watch(clientVisibilityRemoteDataSourceProvider);
  final syncTrigger = ref.watch(syncTriggerProvider);
  return ClientVisibilityRepositoryImpl(local, remote, syncTrigger);
});

final clientVisibilityRepositoryProvider = Provider<ClientVisibilityRepository>((ref) {
  final inner = ref.watch(internalClientVisibilityRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredClientVisibilityRepository(inner, permissionService, currentUser);
});

