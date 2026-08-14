import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/date_formatter.dart';

import '../../../../domain/entities/payment_method.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../controllers/payment_form_controller.dart';
import '../../../../services/attachment_opener_service.dart';
import '../../../providers/repository_providers.dart';
import '../../settings/controllers/settings_controller.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String invoiceId;
  final String paymentId;

  const PaymentFormScreen({
    super.key,
    required this.clientId,
    required this.invoiceId,
    required this.paymentId,
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  
  // List of new files to attach
  final List<String> _newAttachmentPaths = [];
  // List of existing attachments to delete
  final List<String> _deletedAttachmentIds = [];

  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedAttachmentExtensions,
    );

    if (result != null) {
      bool hasLargeFiles = false;
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            if (file.size > AppConstants.maxAttachmentSizeMB * 1024 * 1024) {
              hasLargeFiles = true;
            } else if (!_newAttachmentPaths.contains(file.path!)) {
              _newAttachmentPaths.add(file.path!);
            }
          }
        }
      });
      
      if (hasLargeFiles && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileTooLarge(AppConstants.maxAttachmentSizeMB)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeNewAttachment(String path) {
    setState(() {
      _newAttachmentPaths.remove(path);
    });
  }

  void _removeExistingAttachment(String id) {
    setState(() {
      _deletedAttachmentIds.add(id);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(paymentFormProvider.notifier);
      final existingPayment = ref.read(paymentProvider(widget.paymentId)).value;
      
      final success = await controller.save(
        existingPayment: existingPayment,
        invoiceId: widget.invoiceId,
        clientId: widget.clientId,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        method: _selectedMethod,
        reference: _referenceController.text.isEmpty ? null : _referenceController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        newAttachmentPaths: _newAttachmentPaths,
        deletedAttachmentIds: _deletedAttachmentIds,
      );
      if (success && mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider(widget.paymentId));
    final formState = ref.watch(paymentFormProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final currency = settingsState.value?.currencyCode ?? '\$';
    
    // Check if form is currently saving
    _isSaving = formState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paymentId == 'new' ? AppLocalizations.of(context)!.recordPaymentTitle : AppLocalizations.of(context)!.editPaymentTitle),
      ),
      body: paymentState.when(
        data: (payment) {
          // Initialize controllers once
          if (payment != null && _amountController.text.isEmpty && !_isSaving) {
            _amountController.text = payment.amount.toString();
            _referenceController.text = payment.reference ?? '';
            _notesController.text = payment.notes ?? '';
            _selectedDate = payment.date;
            _selectedMethod = payment.method;
          }

          // Compute visible existing attachments
          final existingAttachments = payment?.attachments.where((a) => !_deletedAttachmentIds.contains(a.id)).toList() ?? [];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.amount, suffixText: currency),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.errorRequired;
                    if (double.tryParse(value) == null) return AppLocalizations.of(context)!.errorInvalidNumber;
                    if (double.parse(value) <= 0) return AppLocalizations.of(context)!.errorGreaterThanZero;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.date),
                  subtitle: Text(DateFormatter.formatDate(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: _selectedMethod,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.methodLabel),
                  items: PaymentMethod.values.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMethod = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.referenceLabel),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.notesOptionalLabel),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.attachmentsLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.attachmentHint(AppConstants.maxAttachmentSizeMB, AppConstants.allowedAttachmentExtensions.join(', ')),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(AppLocalizations.of(context)!.addFile),
                      onPressed: _pickFiles,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Existing attachments
                ...existingAttachments.map((a) => ListTile(
                  leading: const Icon(Icons.attachment),
                  title: Text(a.originalFileName),
                  onTap: () async {
                    final absolutePath = await ref.read(attachmentFileDataSourceProvider).getAbsolutePath(a.filePath);
                    if (context.mounted) {
                      ref.read(attachmentOpenerServiceProvider).openAttachment(context, absolutePath);
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeExistingAttachment(a.id),
                  ),
                )),
                
                // New attachments
                ..._newAttachmentPaths.map((path) => ListTile(
                  leading: const Icon(Icons.new_releases, color: Colors.green),
                  title: Text(p.basename(path)),
                  onTap: () {
                    ref.read(attachmentOpenerServiceProvider).openAttachment(context, path);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeNewAttachment(path),
                  ),
                )),

                if (existingAttachments.isEmpty && _newAttachmentPaths.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(AppLocalizations.of(context)!.noAttachmentsAdded, style: const TextStyle(color: Colors.grey)),
                  ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppLocalizations.of(context)!.savePayment),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => LoadingView(message: AppLocalizations.of(context)!.loadingPayment),
        error: (error, _) => ErrorView(
          message: error.toString().localize(context),
          onRetry: () => ref.invalidate(paymentProvider(widget.paymentId)),
        ),
      ),
    );
  }
}
