import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import 'package:payme/l10n/app_localizations.dart';

class AttachmentViewerScreen extends StatelessWidget {
  final String filePath;

  const AttachmentViewerScreen({
    super.key,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final ext = p.extension(filePath).toLowerCase();
    final filename = p.basename(filePath);

    if (!file.existsSync()) {
      return Scaffold(
        appBar: AppBar(title: Text(filename)),
        body: Center(
          child: Text(AppLocalizations.of(context)!.errorAttachmentNotFound, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final isPdf = ext == '.pdf';
    final isImage = ['.png', '.jpg', '.jpeg'].contains(ext);

    return Scaffold(
      appBar: AppBar(
        title: Text(filename),
      ),
      body: Builder(
        builder: (context) {
          if (isPdf) {
            return PdfPreview(
              build: (format) async => file.readAsBytes(),
              allowSharing: true,
              allowPrinting: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
            );
          } else if (isImage) {
            return Center(
              child: InteractiveViewer(
                child: Image.file(file),
              ),
            );
          } else {
            return Center(
              child: Text(AppLocalizations.of(context)!.errorUnsupportedFormat),
            );
          }
        },
      ),
    );
  }
}
