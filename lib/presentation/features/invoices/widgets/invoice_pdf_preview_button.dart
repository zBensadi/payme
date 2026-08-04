import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/invoice.dart';
import '../utils/pdf_preview_helper.dart';
import 'package:payme/l10n/app_localizations.dart';

class InvoicePdfPreviewButton extends ConsumerStatefulWidget {
  final Invoice invoice;

  const InvoicePdfPreviewButton({
    super.key,
    required this.invoice,
  });

  @override
  ConsumerState<InvoicePdfPreviewButton> createState() => _InvoicePdfPreviewButtonState();
}

class _InvoicePdfPreviewButtonState extends ConsumerState<InvoicePdfPreviewButton> {
  bool _isLoading = false;

  Future<void> _openPreview(BuildContext context) async {
    setState(() => _isLoading = true);
    
    try {
      if (context.mounted) {
        await PdfPreviewHelper.openPreview(context, ref, widget.invoice);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneratePdf(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.picture_as_pdf),
      tooltip: AppLocalizations.of(context)!.generatePdf,
      onPressed: () => _openPreview(context),
    );
  }
}
