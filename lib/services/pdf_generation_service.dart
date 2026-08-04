import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/entities/invoice.dart';
import '../domain/entities/client.dart';
import '../domain/entities/business_settings.dart';
import '../domain/entities/payment.dart';

class PdfGenerationService {
  /// Generates a PDF document for an invoice.
  /// 
  /// This is a completely pure function. It performs no I/O.
  /// The caller must provide all necessary data, including the loaded [logoBytes] if a logo exists.
  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Client client,
    required BusinessSettings settings,
    required List<Payment> payments, // To calculate totals/remaining
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();

    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final remainingBalance = invoice.amount - totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildFooter(context),
        build: (context) {
          return [
            _buildHeader(invoice),
            pw.SizedBox(height: 24),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: _buildBusinessSection(settings, logoBytes)),
                pw.SizedBox(width: 32),
                pw.Expanded(child: _buildClientSection(client)),
              ],
            ),
            pw.SizedBox(height: 32),
            _buildInvoiceSection(invoice),
            pw.SizedBox(height: 32),
            _buildTotals(invoice, totalPaid, remainingBalance, settings.currencyCode),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Invoice invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '#${invoice.invoiceNumber}',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBusinessSection(BusinessSettings settings, Uint8List? logoBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logoBytes != null) ...[
          pw.Container(
            height: 60,
            child: pw.Image(pw.MemoryImage(logoBytes)),
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Text(
          settings.businessName ?? 'Business Name Not Set',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        if (settings.address != null && settings.address!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(settings.address!, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (settings.phone != null && settings.phone!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('Phone: ${settings.phone!}', style: const pw.TextStyle(fontSize: 12)),
        ],
        if (settings.email != null && settings.email!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('Email: ${settings.email!}', style: const pw.TextStyle(fontSize: 12)),
        ],
      ],
    );
  }

  pw.Widget _buildClientSection(Client client) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'BILL TO',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          client.name,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.right,
        ),
        if (client.address != null && client.address!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(client.address!, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (client.phone != null && client.phone!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('Phone: ${client.phone!}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (client.email != null && client.email!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('Email: ${client.email!}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12)),
        ],
      ],
    );
  }

  pw.Widget _buildInvoiceSection(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildDetailColumn('Date', _formatDate(invoice.date)),
            if (invoice.dueDate != null)
              _buildDetailColumn('Due Date', _formatDate(invoice.dueDate!)),
            _buildDetailColumn('Amount', invoice.amount.toStringAsFixed(2)),
          ],
        ),
        if (invoice.description != null && invoice.description!.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          pw.Text(
            'Description',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(invoice.description!),
          ),
        ],
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            'Notes',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 12)),
        ],
      ],
    );
  }

  pw.Widget _buildDetailColumn(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildTotals(Invoice invoice, double totalPaid, double remainingBalance, String currencyCode) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            _buildTotalRow('Total Invoiced', invoice.amount, currencyCode),
            pw.SizedBox(height: 4),
            _buildTotalRow('Total Paid', totalPaid, currencyCode),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            _buildTotalRow(
              'Remaining Balance',
              remainingBalance,
              currencyCode,
              isBold: true,
              color: remainingBalance <= 0 ? PdfColors.green800 : PdfColors.black,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, String currencyCode, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          '${amount.toStringAsFixed(2)} $currencyCode',
          style: pw.TextStyle(
            fontSize: isBold ? 16 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    final now = DateTime.now();
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by PayMe',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              _formatDate(now),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}
