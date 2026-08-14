import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../providers/repository_providers.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/invoice_form_controller.dart';
import '../widgets/invoice_pdf_preview_button.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import 'package:payme/l10n/app_localizations.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String? invoiceId;

  const InvoiceFormScreen({
    super.key,
    required this.clientId,
    this.invoiceId,
  });

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  
  Invoice? _existingInvoice;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.invoiceId != null && widget.invoiceId != 'new') {
      setState(() => _isLoading = true);
      try {
        final result = await ref.read(invoiceRepositoryProvider).getById(widget.invoiceId!);
        final invoice = result is Success<Invoice?> ? result.value : null;
        if (invoice != null) {
          setState(() {
            _existingInvoice = invoice;
            _amountController.text = invoice.amount.toString();
            _descriptionController.text = invoice.description ?? '';
            _notesController.text = invoice.notes ?? '';
            _date = invoice.date;
            _dueDate = invoice.dueDate;
          });
        } else {
          setState(() => _error = AppLocalizations.of(context)!.errorInvoiceNotFound);
        }
      } catch (e) {
        setState(() => _error = e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final initialDate = isDueDate ? (_dueDate ?? _date) : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      final invoice = _existingInvoice?.copyWith(
            date: _date,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            amount: amount,
            dueDate: _dueDate,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          ) ??
          Invoice(
            id: '',
            accountingYearId: '', // Set by controller
            clientId: widget.clientId,
            invoiceNumber: 0, // Set by controller
            date: _date,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            amount: amount,
            dueDate: _dueDate,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isDirty: true,
          );

      final success = await ref.read(invoiceFormControllerProvider.notifier).save(invoice, widget.clientId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.invoiceSaved), backgroundColor: Colors.green),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _isLoading) return Scaffold(body: LoadingView(message: AppLocalizations.of(context)!.loading));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _loadExisting));

    final isEditing = _existingInvoice != null;
    final formState = ref.watch(invoiceFormControllerProvider);
    final isSaving = formState.isLoading;
    final settingsState = ref.watch(settingsControllerProvider);

    ref.listen<AsyncValue<void>>(invoiceFormControllerProvider, (prev, next) {
      if (next is AsyncError && next.error is! FormatException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString().localize(context).replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.editInvoiceTitle(_existingInvoice!.invoiceNumber.toString()) : AppLocalizations.of(context)!.newInvoiceTitle),
        actions: [
          if (isEditing && !isSaving && _existingInvoice != null)
            InvoicePdfPreviewButton(invoice: _existingInvoice!),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.amountLabel,
                border: const OutlineInputBorder(),
                prefixText: settingsState.hasValue && settingsState.value != null ? '${settingsState.value!.currencyCode} ' : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) return AppLocalizations.of(context)!.errorRequired;
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) return AppLocalizations.of(context)!.errorInvalidAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)!.dateLabel),
              subtitle: Text(DateFormatter.formatDate(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)!.dueDateLabel),
              subtitle: Text(_dueDate != null ? DateFormatter.formatDate(_dueDate!) : AppLocalizations.of(context)!.notSet),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.descriptionLabel, border: const OutlineInputBorder()),
              textInputAction: TextInputAction.next,
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.notesLabel, border: const OutlineInputBorder()),
              textInputAction: TextInputAction.done,
              maxLines: 3,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}
