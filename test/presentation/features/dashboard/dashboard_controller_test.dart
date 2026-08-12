import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:payme/domain/entities/invoice.dart';
import 'package:payme/domain/entities/payment.dart';
import 'package:payme/domain/entities/payment_method.dart';
import 'package:payme/presentation/providers/active_year_provider.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/presentation/features/dashboard/controllers/dashboard_controller.dart';
import 'package:payme/domain/repositories/invoice_repository.dart';
import 'package:payme/domain/repositories/payment_repository.dart';
import 'package:payme/domain/repositories/client_repository.dart';
import 'package:payme/presentation/features/dashboard/models/dashboard_state.dart';
import 'package:payme/domain/entities/client_visibility_context.dart';

class FakeClientRepository implements ClientRepository {
  @override
  Future<Result<List<Client>>> getAllVisible({String? searchQuery, ClientVisibilityContext? visibilityContext}) async {
    return Success([
      Client(id: 'c1', name: 'Client 1', createdAt: DateTime.now(), updatedAt: DateTime.now(), isDeleted: false),
      Client(id: 'c2', name: 'Client 2', createdAt: DateTime.now(), updatedAt: DateTime.now(), isDeleted: false),
    ]);
  }
  @override
  Future<Result<List<Client>>> getAllDeleted({String? searchQuery}) async => const Success([]);
  @override
  Future<Result<Client>> getById(String id) async => Success(Client(id: id, name: 'Client', createdAt: DateTime.now(), updatedAt: DateTime.now(), isDeleted: false));
  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async => const Success(false);
  @override
  Future<Result<Client>> create(Client client) async => Success(client);
  @override
  Future<Result<Client>> update(Client client) async => Success(client);
  @override
  Future<Result<void>> softDelete(String id, {Object? txn}) async => const Success(null);
  @override
  Future<Result<void>> restore(String id) async => const Success(null);
}

class FakeInvoiceRepository implements InvoiceRepository {
  @override
  Future<Result<List<Invoice>>> getInvoicesForYear(String accountingYearId, {ClientVisibilityContext? visibilityContext}) async {
    if (accountingYearId == 'y1') {
      return Success([
        Invoice(id: 'i1', accountingYearId: 'y1', clientId: 'c1', invoiceNumber: 1, date: DateTime.now(), amount: 1000, createdAt: DateTime.now(), updatedAt: DateTime.now(), isDirty: false),
        Invoice(id: 'i2', accountingYearId: 'y1', clientId: 'c2', invoiceNumber: 2, date: DateTime.now(), amount: 500, createdAt: DateTime.now(), updatedAt: DateTime.now(), isDirty: false),
      ]);
    }
    return const Success([]);
  }
  @override
  Future<Result<List<Invoice>>> getInvoicesForClient(String accountingYearId, String clientId, {ClientVisibilityContext? visibilityContext}) async => const Success([]);
  @override
  Future<Result<Invoice?>> getById(String id) async => const Success(null);
  @override
  Future<Result<Invoice>> create(Invoice invoice) async => Success(invoice);
  @override
  Future<Result<Invoice>> update(Invoice invoice) async => Success(invoice);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<int>> getHighestInvoiceNumber(String accountingYearId) async => const Success(0);

  @override
  Future<Result<int>> countAllForClient(String clientId, {Object? txn}) async => const Success(0);

  @override
  Future<Result<void>> deleteAllForClient(String clientId, {Object? txn}) async => const Success(null);

  @override
  Future<Result<void>> transferInvoicesToClient(String oldClientId, String newClientId, {Object? txn}) async => const Success(null);
}

class FakePaymentRepository implements PaymentRepository {
  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice(String invoiceId, {ClientVisibilityContext? visibilityContext}) async {
    if (invoiceId == 'i1') {
      // 200 paid
      return Success([
        Payment(id: 'p1', invoiceId: 'i1', date: DateTime.now(), amount: 200, method: PaymentMethod.bankTransfer, createdAt: DateTime.now(), updatedAt: DateTime.now(), isDirty: false),
      ]);
    } else if (invoiceId == 'i2') {
      // 500 paid (fully paid)
      return Success([
        Payment(id: 'p2', invoiceId: 'i2', date: DateTime.now(), amount: 500, method: PaymentMethod.cash, createdAt: DateTime.now(), updatedAt: DateTime.now(), isDirty: false),
      ]);
    }
    return const Success([]);
  }
  @override
  Future<Result<List<Payment>>> getPaymentsByPeriod(String yearId, {DateTime? start, DateTime? end, ClientVisibilityContext? visibilityContext}) async => const Success([]);
  @override
  Future<Result<Payment?>> getById(String id) async => const Success(null);
  @override
  Future<Result<Payment>> create(Payment payment, {List<String>? newAttachmentSourcePaths}) async => Success(payment);
  @override
  Future<Result<Payment>> update(Payment payment, {List<String>? newAttachmentSourcePaths, List<String>? deletedAttachmentIds}) async => Success(payment);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<String>>> getAttachmentPathsForInvoice(String invoiceId) async => const Success([]);
  @override
  Future<Result<List<String>>> getAttachmentPathsForYear(String yearId) async => const Success([]);
}

void main() {
  test('DashboardController aggregates correct KPIs for active year', () async {
    final year = AccountingYear(id: 'y1', name: '2026', isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now());
    
    final container = ProviderContainer(
      overrides: [
        activeYearProvider.overrideWith((ref) => year),
        clientRepositoryProvider.overrideWithValue(FakeClientRepository()),
        invoiceRepositoryProvider.overrideWithValue(FakeInvoiceRepository()),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
      ],
    );

    final state = await container.read(dashboardControllerProvider.future);
    expect(state, isA<DashboardData>());
    
    final dashboard = state as DashboardData;
    
    expect(dashboard.activeYear.id, 'y1');
    expect(dashboard.clientsCount, 2);
    expect(dashboard.invoicesCount, 2);
    expect(dashboard.totalInvoiced, 1500.0);
    expect(dashboard.totalPaid, 700.0);
    expect(dashboard.outstandingBalance, 800.0);
  });

  test('DashboardController returns DashboardNoYear when there is no active year', () async {
    final container = ProviderContainer(
      overrides: [
        activeYearProvider.overrideWith((ref) => null),
        clientRepositoryProvider.overrideWithValue(FakeClientRepository()),
        invoiceRepositoryProvider.overrideWithValue(FakeInvoiceRepository()),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
      ],
    );

    final state = await container.read(dashboardControllerProvider.future);
    expect(state, isA<DashboardNoYear>());
  });
}
