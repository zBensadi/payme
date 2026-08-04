import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../../core/storage/app_paths.dart';
import 'package:path/path.dart' as p;

import '../../../../domain/entities/invoice.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/payment.dart';
import '../../../../core/error/result.dart';
import '../../../providers/repository_providers.dart';
import '../../settings/controllers/settings_controller.dart';

class PdfPreviewHelper {
  static Future<void> openPreview(BuildContext context, WidgetRef ref, Invoice invoice) async {
    try {
      final settingsState = ref.read(settingsControllerProvider);
      final settings = settingsState.value;
      if (settings == null) throw Exception('Business settings not loaded');

      final clientResult = await ref.read(clientRepositoryProvider).getById(invoice.clientId);
      final client = clientResult is Success<Client> ? clientResult.value : null;
      if (client == null) throw Exception('Client not found');

      final paymentsResult = await ref.read(paymentRepositoryProvider).getPaymentsForInvoice(invoice.id);
      final payments = paymentsResult is Success<List<Payment>> ? paymentsResult.value : <Payment>[];

      Uint8List? logoBytes;
      if (settings.logoPath != null && settings.logoPath!.isNotEmpty) {
        try {
          final logosDir = await AppPaths.getLogosPath();
          final file = File(p.join(logosDir, settings.logoPath));
          if (await file.exists()) {
            logoBytes = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint('Failed to load logo bytes: $e');
        }
      }

      final service = ref.read(pdfGenerationServiceProvider);
      final pdfBytes = await service.generateInvoicePdf(
        invoice: invoice,
        client: client,
        settings: settings,
        payments: payments,
        logoBytes: logoBytes,
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Invoice #${invoice.invoiceNumber}')),
              body: PdfPreview(
                build: (format) async => pdfBytes,
                allowSharing: true,
                allowPrinting: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
