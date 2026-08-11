import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:arabic_reshaper/arabic_reshaper.dart';

import '../domain/entities/invoice.dart';
import '../domain/entities/client.dart';
import '../domain/entities/business_settings.dart';
import '../domain/entities/payment.dart';
import '../core/pdf/pdf_localizations.dart';
import '../core/formatters/formatters.dart';

import 'package:flutter/services.dart' show rootBundle;

class PdfGenerationService {
  final PdfLocalizations _localizations;

  PdfGenerationService(this._localizations);

  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Client client,
    required BusinessSettings settings,
    required List<Payment> payments,
    Uint8List? logoBytes,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBoldData);
    
    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
    );

    final pdf = pw.Document(theme: theme);

    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final remainingBalance = invoice.amount - totalPaid;

    final isRtl = settings.languageCode == 'ar';
    final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    if (settings.defaultDocumentLayout == 'duplicate') {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: textDirection,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.FittedBox(
                          fit: pw.BoxFit.scaleDown,
                          alignment: pw.Alignment.topLeft,
                          child: pw.Container(
                            width: PdfPageFormat.a4.width - 64, // maintain standard layout width
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: _buildInvoiceWidgets(invoice, client, settings, totalPaid, remainingBalance, logoBytes),
                            ),
                          ),
                        ),
                      ),
                      _buildFooter(context),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 16),
                  child: pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.FittedBox(
                          fit: pw.BoxFit.scaleDown,
                          alignment: pw.Alignment.topLeft,
                          child: pw.Container(
                            width: PdfPageFormat.a4.width - 64, // maintain standard layout width
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: _buildInvoiceWidgets(invoice, client, settings, totalPaid, remainingBalance, logoBytes),
                            ),
                          ),
                        ),
                      ),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: textDirection,
          margin: const pw.EdgeInsets.all(32),
          footer: (context) => _buildFooter(context),
          build: (context) {
            return _buildInvoiceWidgets(invoice, client, settings, totalPaid, remainingBalance, logoBytes);
          },
        ),
      );
    }

    return pdf.save();
  }

  List<pw.Widget> _buildInvoiceWidgets(
    Invoice invoice,
    Client client,
    BusinessSettings settings,
    double totalPaid,
    double remainingBalance,
    Uint8List? logoBytes,
  ) {
    return [
      _buildHeader(invoice, settings),
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
  }

  pw.Widget _buildHeader(Invoice invoice, BusinessSettings settings) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildText(
            settings.defaultDocumentTitle.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          _buildText(
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
        _buildText(
          settings.businessName ?? 'Business Name Not Set',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        if (settings.address != null && settings.address!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(settings.address!, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (settings.phone != null && settings.phone!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(settings.phone!, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (settings.email != null && settings.email!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(settings.email!, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (settings.rc != null && settings.rc!.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          _buildText('${_localizations.rc}: ${settings.rc}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
        if (settings.nif != null && settings.nif!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _buildText('${_localizations.nif}: ${settings.nif}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
        if (settings.nis != null && settings.nis!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _buildText('${_localizations.nis}: ${settings.nis}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
        if (settings.art != null && settings.art!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _buildText('${_localizations.art}: ${settings.art}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
      ],
    );
  }

  pw.Widget _buildClientSection(Client client) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildText(
          _localizations.billTo.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildText(
          client.name,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.right,
        ),
        if (client.address != null && client.address!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(client.address!, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (client.phone != null && client.phone!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(client.phone!, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (client.email != null && client.email!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(client.email!, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (client.rc != null && client.rc!.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          _buildText('${_localizations.rc}: ${client.rc}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
        if (client.nif != null && client.nif!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _buildText('${_localizations.nif}: ${client.nif}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
        if (client.nis != null && client.nis!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _buildText('${_localizations.nis}: ${client.nis}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
        if (client.art != null && client.art!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _buildText('${_localizations.art}: ${client.art}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
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
            _buildDetailColumn(_localizations.date, _formatDate(invoice.date)),
            if (invoice.dueDate != null)
              _buildDetailColumn(_localizations.dueDate, _formatDate(invoice.dueDate!)),
            _buildDetailColumn(_localizations.amount, NumberFormatter.formatAmount(invoice.amount)),
          ],
        ),
        if (invoice.description != null && invoice.description!.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _buildText(
            _localizations.description,
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
            child: _buildText(invoice.description!),
          ),
        ],
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _buildText(
            _localizations.notes,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          _buildText(invoice.notes!, style: const pw.TextStyle(fontSize: 12)),
        ],
      ],
    );
  }

  pw.Widget _buildDetailColumn(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildText(
          title,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        _buildText(
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
            _buildTotalRow(_localizations.totalInvoiced, invoice.amount, currencyCode),
            pw.SizedBox(height: 4),
            _buildTotalRow(_localizations.totalPaid, totalPaid, currencyCode),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            _buildTotalRow(
              _localizations.remainingBalance,
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
        _buildText(
          label,
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey700,
          ),
        ),
        _buildText(
          '${NumberFormatter.formatAmount(amount)} $currencyCode',
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
            _buildText(
              _localizations.generatedBy,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            _buildText(
              _formatDate(now),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            _buildText(
              '${_localizations.page} ${context.pageNumber} ${_localizations.of} ${context.pagesCount}',
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

  pw.Widget _buildText(String text, {pw.TextStyle? style, pw.TextAlign? textAlign, pw.TextDirection? textDirection}) {
    final reshaped = ArabicReshaper.instance.reshape(text);
    // Explicitly enforce RTL if the text contains Arabic characters or presentation forms
    final hasArabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
    final effectiveDirection = textDirection ?? (hasArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr);
    
    return pw.Text(
      reshaped,
      style: style,
      textAlign: textAlign,
      textDirection: effectiveDirection,
    );
  }
}
