import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final csvExportServiceProvider = Provider((ref) => CsvExportService());

class CsvExportService {
  Future<void> exportCsv(BuildContext context, String csvContent, String defaultFileName) async {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: defaultFileName,
          acceptedTypeGroups: [
            const XTypeGroup(label: 'CSV', extensions: ['csv']),
          ],
        );
        if (result != null) {
          final file = File(result.path);
          await file.writeAsString(csvContent);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exported successfully!'), backgroundColor: Colors.green),
            );
          }
        }
      } else {
        // Mobile platform fallback
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$defaultFileName');
        await file.writeAsString(csvContent);
        
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], subject: defaultFileName);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
