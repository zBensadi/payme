import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/storage/app_paths.dart';

class AttachmentFileDataSource {
  /// Copies the source file into the managed attachments directory and returns the relative path
  Future<String> saveAttachment(String sourceFilePath, String newFileName) async {
    final attachmentsDirStr = await AppPaths.getAttachmentsPath();
    final sourceFile = File(sourceFilePath);
    
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourceFilePath');
    }

    final destPath = p.join(attachmentsDirStr, newFileName);
    await sourceFile.copy(destPath);
    
    // We store only the relative path (just the file name in this case)
    // so the database is portable across machines and backup restorations.
    return newFileName;
  }

  /// Deletes the attachment file from the managed directory given its relative path
  Future<void> deleteAttachment(String relativeFilePath) async {
    final attachmentsDirStr = await AppPaths.getAttachmentsPath();
    final file = File(p.join(attachmentsDirStr, relativeFilePath));
    
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Returns the absolute path of an attachment given its relative path
  Future<String> getAbsolutePath(String relativeFilePath) async {
    final attachmentsDirStr = await AppPaths.getAttachmentsPath();
    return p.join(attachmentsDirStr, relativeFilePath);
  }
}
