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
import '../core/formatters/amount_to_words_formatter.dart';

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
    required String generatedByName,
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

    bool useDuplicate = settings.defaultDocumentLayout == 'duplicate';
    if (useDuplicate && !_canFitCompactDuplicate(invoice, settings, client)) {
      useDuplicate = false; // Fallback to standard layout for overly dense content
    }

    if (useDuplicate) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: textDirection,
          margin: const pw.EdgeInsets.only(left: 32, top: 24, right: 32, bottom: 16),
          build: (context) {
            return pw.Column(
              children: [
                pw.Expanded(
                  child: _buildCompactInvoiceColumn(invoice, client, settings, totalPaid, remainingBalance, logoBytes, generatedByName),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12),
                  child: pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                ),
                pw.Expanded(
                  child: _buildCompactInvoiceColumn(invoice, client, settings, totalPaid, remainingBalance, logoBytes, generatedByName),
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
          margin: const pw.EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
          footer: (context) => _buildFooter(context, generatedByName),
          build: (context) {
            return _buildInvoiceWidgets(invoice, client, settings, totalPaid, remainingBalance, logoBytes);
          },
        ),
      );
    }

    return pdf.save();
  }

  bool _canFitCompactDuplicate(Invoice invoice, BusinessSettings settings, Client client) {
    if (invoice.notes != null && invoice.notes!.length > 150) return false;
    if (client.address != null && client.address!.length > 100) return false;
    if (settings.address != null && settings.address!.length > 100) return false;
    if (invoice.description != null && invoice.description!.length > 300) return false;
    return true;
  }

  pw.Widget _buildCompactInvoiceColumn(
    Invoice invoice,
    Client client,
    BusinessSettings settings,
    double totalPaid,
    double remainingBalance,
    Uint8List? logoBytes,
    String generatedByName,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildCompactHeader(invoice, settings, logoBytes)),
            pw.SizedBox(width: 16),
            pw.Expanded(child: _buildCompactClientSection(invoice, client)),
          ],
        ),
        pw.SizedBox(height: 8),
        _buildCompactInvoiceSection(invoice),
        pw.SizedBox(height: 8),
        _buildTotals(invoice, totalPaid, remainingBalance, settings.currencyCode, settings.languageCode),
        pw.Spacer(),
        _buildCompactFooter(generatedByName),
      ],
    );
  }

  pw.Widget _buildCompactFooter(String generatedByName) {
    final now = DateTime.now();
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300, height: 1),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildText(_localizations.generatedBy(generatedByName)),
              _buildText(_formatDate(now)),
              _buildText('${_localizations.page} 1 ${_localizations.of} 1'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactHeader(Invoice invoice, BusinessSettings settings, Uint8List? logoBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoBytes != null) ...[
              pw.Container(
                height: 30,
                child: pw.Image(pw.MemoryImage(logoBytes)),
              ),
              pw.SizedBox(width: 8),
            ],
            pw.Expanded(
              child: _buildText(
                settings.businessName ?? 'Business Name Not Set',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        if (settings.address != null && settings.address!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(settings.address!, style: const pw.TextStyle(fontSize: 9)),
        ],
        pw.SizedBox(height: 4),
        pw.Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            if (settings.rc != null && settings.rc!.isNotEmpty)
              _buildText('${_localizations.rc}: ${settings.rc}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            if (settings.nif != null && settings.nif!.isNotEmpty)
              _buildText('${_localizations.nif}: ${settings.nif}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            if (settings.nis != null && settings.nis!.isNotEmpty)
              _buildText('${_localizations.nis}: ${settings.nis}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            if (settings.art != null && settings.art!.isNotEmpty)
              _buildText('${_localizations.art}: ${settings.art}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: _buildText(
                settings.defaultDocumentTitle.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            _buildText(
              '#${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCompactClientSection(Invoice invoice, Client client) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildCompactDetailColumn(_localizations.date, _formatDate(invoice.date)),
            if (invoice.dueDate != null)
              _buildCompactDetailColumn(_localizations.dueDate, _formatDate(invoice.dueDate!)),
          ],
        ),
        pw.SizedBox(height: 8),
        _buildText(
          _localizations.billTo.toUpperCase(),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        _buildText(
          client.name,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        if (client.address != null && client.address!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _buildText(
            client.address!, 
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            if (client.rc != null && client.rc!.isNotEmpty)
              _buildText('${_localizations.rc}: ${client.rc}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            if (client.nif != null && client.nif!.isNotEmpty)
              _buildText('${_localizations.nif}: ${client.nif}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            if (client.nis != null && client.nis!.isNotEmpty)
              _buildText('${_localizations.nis}: ${client.nis}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            if (client.art != null && client.art!.isNotEmpty)
              _buildText('${_localizations.art}: ${client.art}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCompactDetailColumn(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildText(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        _buildText(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildCompactInvoiceSection(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (invoice.description != null && invoice.description!.isNotEmpty) ...[
          _buildText(
            _localizations.description,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: _buildText(
              invoice.description!, 
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _buildText(
            _localizations.notes,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          _buildText(
            invoice.notes!, 
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ],
    );
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
      _buildHeader(invoice, settings, logoBytes),
      pw.SizedBox(height: 24),
      _buildClientAndDateSection(invoice, client),
      pw.SizedBox(height: 16),
      _buildInvoiceSection(invoice),
      pw.SizedBox(height: 16),
      _buildTotals(invoice, totalPaid, remainingBalance, settings.currencyCode, settings.languageCode),
    ];
  }

  pw.Widget _buildHeader(Invoice invoice, BusinessSettings settings, Uint8List? logoBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoBytes != null) ...[
              pw.Container(
                height: 50,
                child: pw.Image(pw.MemoryImage(logoBytes)),
              ),
              pw.SizedBox(width: 8),
            ],
            pw.Expanded(
              child: _buildText(
                settings.businessName ?? 'Business Name Not Set',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        if (settings.address != null && settings.address!.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _buildText(settings.address!, style: const pw.TextStyle(fontSize: 10)),
        ],
        pw.SizedBox(height: 4),
        pw.Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (settings.phone != null && settings.phone!.isNotEmpty)
              _buildText(settings.phone!, style: const pw.TextStyle(fontSize: 10)),
            if (settings.email != null && settings.email!.isNotEmpty)
              _buildText(settings.email!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (settings.rc != null && settings.rc!.isNotEmpty)
              _buildText('${_localizations.rc}: ${settings.rc}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            if (settings.nif != null && settings.nif!.isNotEmpty)
              _buildText('${_localizations.nif}: ${settings.nif}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            if (settings.nis != null && settings.nis!.isNotEmpty)
              _buildText('${_localizations.nis}: ${settings.nis}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            if (settings.art != null && settings.art!.isNotEmpty)
              _buildText('${_localizations.art}: ${settings.art}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildText(
                settings.defaultDocumentTitle.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            _buildText(
              '#${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClientAndDateSection(Invoice invoice, Client client) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left 50% - Dates
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailColumn(_localizations.date, _formatDate(invoice.date)),
              if (invoice.dueDate != null) ...[
                pw.SizedBox(height: 12),
                _buildDetailColumn(_localizations.dueDate, _formatDate(invoice.dueDate!)),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        // Right 50% - Client Info (Left-aligned in LTR, mirrors in RTL)
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildText(
                _localizations.billTo.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              _buildText(
                client.name,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              if (client.address != null && client.address!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                _buildText(client.address!, style: const pw.TextStyle(fontSize: 10)),
              ],
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (client.phone != null && client.phone!.isNotEmpty)
                    _buildText(client.phone!, style: const pw.TextStyle(fontSize: 10)),
                  if (client.email != null && client.email!.isNotEmpty)
                    _buildText(client.email!, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (client.rc != null && client.rc!.isNotEmpty)
                    _buildText('${_localizations.rc}: ${client.rc}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  if (client.nif != null && client.nif!.isNotEmpty)
                    _buildText('${_localizations.nif}: ${client.nif}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  if (client.nis != null && client.nis!.isNotEmpty)
                    _buildText('${_localizations.nis}: ${client.nis}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  if (client.art != null && client.art!.isNotEmpty)
                    _buildText('${_localizations.art}: ${client.art}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceSection(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (invoice.description != null && invoice.description!.isNotEmpty) ...[
          _buildText(
            _localizations.description,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: _buildText(invoice.description!, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _buildText(
            _localizations.notes,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          _buildText(invoice.notes!, style: const pw.TextStyle(fontSize: 11)),
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

  pw.Widget _buildTotals(Invoice invoice, double totalPaid, double remainingBalance, String currencyCode, String languageCode) {
    final amountInWords = AmountToWordsFormatter.formatAmount(invoice.amount, languageCode);
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left 50% - Amount in words
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            padding: const pw.EdgeInsets.only(right: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 8), // align with totals divider
                _buildText(
                  amountInWords,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right 50% - Numeric totals
        pw.Expanded(
          flex: 1,
          child: pw.Container(
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
          ),
        ),
      ],
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

  pw.Widget _buildFooter(pw.Context context, String generatedByName) {
    final now = DateTime.now();
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8), // minimize footer margin
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Divider(color: PdfColors.grey300, height: 1),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildText(
                _localizations.generatedBy(generatedByName),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              _buildText(
                _formatDate(now),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              _buildText(
                '${_localizations.page} ${context.pageNumber} ${_localizations.of} ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
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
