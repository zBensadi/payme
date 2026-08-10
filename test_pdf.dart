import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();
  
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          children: [
            pw.Expanded(
              child: pw.FittedBox(
                fit: pw.BoxFit.scaleDown,
                alignment: pw.Alignment.topCenter,
                child: pw.Container(
                  width: PdfPageFormat.a4.width - 64, // maintain width
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(height: 100, color: PdfColors.red), // Header
                      pw.SizedBox(height: 24),
                      pw.Container(height: 100, color: PdfColors.blue), // Row
                      pw.SizedBox(height: 32),
                      pw.Container(height: 100, color: PdfColors.green), // Invoice section
                      pw.SizedBox(height: 32),
                      pw.Container(height: 150, color: PdfColors.yellow), // Totals
                    ],
                  ),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 16),
              child: pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
            ),
            pw.Expanded(
              child: pw.FittedBox(
                fit: pw.BoxFit.scaleDown,
                alignment: pw.Alignment.topCenter,
                child: pw.Container(
                  width: PdfPageFormat.a4.width - 64, // maintain width
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(height: 100, color: PdfColors.red), // Header
                      pw.SizedBox(height: 24),
                      pw.Container(height: 100, color: PdfColors.blue), // Row
                      pw.SizedBox(height: 32),
                      pw.Container(height: 100, color: PdfColors.green), // Invoice section
                      pw.SizedBox(height: 32),
                      pw.Container(height: 150, color: PdfColors.yellow), // Totals
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  final file = File('test_pdf.pdf');
  await file.writeAsBytes(await pdf.save());
  print('Done');
}
