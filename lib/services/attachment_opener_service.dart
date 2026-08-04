import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attachmentOpenerServiceProvider = Provider<AttachmentOpenerService>((ref) {
  return AttachmentOpenerService();
});

class AttachmentOpenerService {
  /// Opens the attachment in a platform-agnostic way.
  /// Currently utilizes the internal AttachmentViewerScreen via GoRouter.
  Future<void> openAttachment(BuildContext context, String absolutePath) async {
    context.push('/attachment-viewer', extra: absolutePath);
  }
}
