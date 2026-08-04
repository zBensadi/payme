import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/invoice.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:payme/domain/entities/business_settings.dart';
import 'package:payme/domain/entities/payment.dart';
import 'package:payme/domain/entities/payment_method.dart';
import 'package:payme/services/pdf_generation_service.dart';

void main() {
  late PdfGenerationService service;

  setUp(() {
    service = PdfGenerationService();
  });

  test('generateInvoicePdf creates valid non-empty PDF bytes without logo', () async {
    final client = Client(
      id: 'c1',
      name: 'Acme Corp',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final invoice = Invoice(
      id: 'inv1',
      accountingYearId: 'y1',
      clientId: 'c1',
      invoiceNumber: 101,
      date: DateTime.now(),
      amount: 1500.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: false,
    );

    final settings = BusinessSettings(
      id: 1,
      currencyCode: 'USD',
      businessName: 'My Awesome Business',
    );

    final pdfBytes = await service.generateInvoicePdf(
      invoice: invoice,
      client: client,
      settings: settings,
      payments: [],
    );

    expect(pdfBytes, isNotEmpty);
    // PDF magic number check (starts with %PDF-)
    expect(pdfBytes.sublist(0, 5), equals([37, 80, 68, 70, 45]));
  });

  test('generateInvoicePdf layout handles extremely long strings without throwing', () async {
    final client = Client(
      id: 'c1',
      name: 'A very very very very very very very very very very very very very very very long name',
      address: 'An exceptionally exceptionally exceptionally exceptionally exceptionally exceptionally exceptionally long address that might break layout if not wrapped properly',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final invoice = Invoice(
      id: 'inv1',
      accountingYearId: 'y1',
      clientId: 'c1',
      invoiceNumber: 9999999,
      date: DateTime.now(),
      amount: 1500000.0,
      description: 'Super long description ' * 50,
      notes: 'Super long notes ' * 50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: false,
    );

    final settings = BusinessSettings(
      id: 1,
      currencyCode: 'USD',
      businessName: 'An absolutely incredibly massively long business name to ensure text wrapping functions',
      address: 'Another incredibly long address for the business side just to be completely sure',
    );

    final payments = [
      Payment(
        id: 'p1',
        invoiceId: 'inv1',
        date: DateTime.now(),
        amount: 500000.0,
        method: PaymentMethod.bankTransfer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDirty: true,
      ),
    ];

    // Should not throw any rendering/layout exceptions
    final pdfBytes = await service.generateInvoicePdf(
      invoice: invoice,
      client: client,
      settings: settings,
      payments: payments,
      logoBytes: null,
    );

    expect(pdfBytes, isNotEmpty);
  });
}
