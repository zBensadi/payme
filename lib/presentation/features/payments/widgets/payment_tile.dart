import 'package:flutter/material.dart';
import '../../../../core/formatters/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/payment.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/storage/app_paths.dart';
import 'package:path/path.dart' as p;
import '../../../../services/attachment_opener_service.dart';
import 'payment_method_badge.dart';
import '../../settings/controllers/settings_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

class PaymentTile extends ConsumerWidget {
  final Payment payment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String attachmentId) onDeleteAttachment;

  const PaymentTile({
    super.key,
    required this.payment,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteAttachment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final currency = settingsState.value?.currencyCode ?? '\$';

    return ListTile(
      title: Text('${NumberFormatter.formatAmount(payment.amount)} $currency'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormatter.formatDate(payment.date)),
          if (payment.reference != null && payment.reference!.isNotEmpty)
            Text(AppLocalizations.of(context)!.refPrefix(payment.reference!), style: const TextStyle(fontSize: 12)),
          if (payment.attachments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: payment.attachments.map((attachment) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        attachment.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment.originalFileName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${attachment.fileType.toUpperCase()} • ${(attachment.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        tooltip: AppLocalizations.of(context)!.openAttachment,
                        onPressed: () async {
                          final basePath = await AppPaths.getAttachmentsPath();
                          final absPath = p.join(basePath, attachment.filePath);
                          if (context.mounted) {
                            ref.read(attachmentOpenerServiceProvider).openAttachment(context, absPath);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        tooltip: AppLocalizations.of(context)!.deleteAttachmentTitle,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.deleteAttachmentTitle),
                              content: Text(AppLocalizations.of(context)!.deleteAttachmentConfirm),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: Text(AppLocalizations.of(context)!.delete)),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            onDeleteAttachment(attachment.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      isThreeLine: payment.reference != null || payment.attachments.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PaymentMethodBadge(method: payment.method),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
              PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}
