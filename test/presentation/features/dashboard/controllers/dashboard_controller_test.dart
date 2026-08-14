import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/error/failures.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:payme/domain/entities/invoice.dart';
import 'package:payme/domain/entities/payment.dart';
import 'package:payme/domain/entities/client_visibility_context.dart';
import 'package:payme/domain/repositories/client_repository.dart';
import 'package:payme/domain/repositories/invoice_repository.dart';
import 'package:payme/domain/repositories/payment_repository.dart';
import 'package:payme/presentation/features/dashboard/controllers/dashboard_controller.dart';
import 'package:payme/presentation/features/dashboard/models/dashboard_state.dart';
import 'package:payme/presentation/providers/active_year_provider.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/data/repositories_impl/accounting_year_repository_impl.dart';
import 'package:payme/domain/repositories/accounting_year_repository.dart';
import 'package:payme/core/events/repository_event.dart';
import 'dart:async';

class FakeClientRepository implements ClientRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<List<Client>>> getAllVisible({String? searchQuery, ClientVisibilityContext? visibilityContext}) async {
    return const Success([]);
  }
}

class FakePaymentRepository implements PaymentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice(String invoiceId, {ClientVisibilityContext? visibilityContext}) async {
    return const Success([]);
  }
}

class FakeUnauthorizedInvoiceRepository implements InvoiceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<List<Invoice>>> getInvoicesForYear(String yearId, {ClientVisibilityContext? visibilityContext}) async {
    return const Failure(AuthFailure('Unauthorized access to invoice data.'));
  }
}

class FakeInternalAccountingYearRepo implements AccountingYearRepositoryImpl {
  final _eventController = StreamController<RepositoryEvent>.broadcast();
  AccountingYear? yearToReturn;

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<AccountingYear?>> getActive() async {
    return Success(yearToReturn);
  }
}

class FakeSecuredAccountingYearRepo implements AccountingYearRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<AccountingYear?>> getActive() async {
    return const Failure(AuthFailure('You do not have permission to view accounting years.'));
  }
}

void main() {
  test('Dashboard gracefully handles unauthorized invoice access', () async {
    final container = ProviderContainer(
      overrides: [
        activeYearProvider.overrideWith((ref) => AccountingYear(id: 'y1', name: '2026', isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now())),
        clientRepositoryProvider.overrideWithValue(FakeClientRepository()),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
        invoiceRepositoryProvider.overrideWithValue(FakeUnauthorizedInvoiceRepository()),
      ],
    );

    final dashboardState = await container.read(dashboardControllerProvider.future);

    expect(dashboardState, isA<DashboardData>());
    final data = dashboardState as DashboardData;
    expect(data.invoicesCount, 0);
    expect(data.totalInvoiced, 0.0);
    expect(data.outstandingBalance, 0.0);
  });

  test('DashboardController loads normally when user lacks view permission but active year exists', () async {
    final fakeInternalRepo = FakeInternalAccountingYearRepo();
    fakeInternalRepo.yearToReturn = AccountingYear(id: 'y1', name: '2026', isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now());

    final container = ProviderContainer(
      overrides: [
        internalAccountingYearRepositoryProvider.overrideWithValue(fakeInternalRepo),
        accountingYearRepositoryProvider.overrideWithValue(FakeSecuredAccountingYearRepo()),
        clientRepositoryProvider.overrideWithValue(FakeClientRepository()),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
        invoiceRepositoryProvider.overrideWithValue(FakeUnauthorizedInvoiceRepository()),
      ],
    );

    // Verify activeYearProvider successfully bypasses the secured wrapper and returns the year
    final activeYear = await container.read(activeYearProvider.future);
    expect(activeYear, isNotNull);
    expect(activeYear!.id, 'y1');

    final dashboardState = await container.read(dashboardControllerProvider.future);

    // Should NOT be DashboardNoYear
    expect(dashboardState, isA<DashboardData>());
  });

  test('DashboardController returns DashboardNoYear when no active year genuinely exists', () async {
    final fakeInternalRepo = FakeInternalAccountingYearRepo();
    fakeInternalRepo.yearToReturn = null; // No year exists

    final container = ProviderContainer(
      overrides: [
        internalAccountingYearRepositoryProvider.overrideWithValue(fakeInternalRepo),
        accountingYearRepositoryProvider.overrideWithValue(FakeSecuredAccountingYearRepo()),
        clientRepositoryProvider.overrideWithValue(FakeClientRepository()),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
        invoiceRepositoryProvider.overrideWithValue(FakeUnauthorizedInvoiceRepository()),
      ],
    );

    // activeYearProvider should return null
    final activeYear = await container.read(activeYearProvider.future);
    expect(activeYear, isNull);

    final dashboardState = await container.read(dashboardControllerProvider.future);

    // Should be DashboardNoYear because there is genuinely no active year
    expect(dashboardState, isA<DashboardNoYear>());
  });
}
