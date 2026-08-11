import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:arabic_reshaper/arabic_reshaper.dart';

void main() async {
  final pdf = pw.Document();
  final bytes = File('assets/fonts/Amiri-Regular.ttf').readAsBytesSync();
  final ttf = pw.Font.ttf(bytes.buffer.asByteData());
  final text = 'هونورار';
  
  pw.Widget _buildText(String text) {
    final reshaped = ArabicReshaper.instance.reshape(text);
    final hasArabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
    return pw.Text(reshaped, textDirection: hasArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr);
  }

  pdf.addPage(pw.Page(
    theme: pw.ThemeData.withFont(base: ttf),
    build: (pw.Context context) {
      return pw.Column(children: [
        _buildText(text),
      ]);
    }
  ));
  File('test_output.pdf').writeAsBytesSync(await pdf.save());
  print('PDF generated');
}
