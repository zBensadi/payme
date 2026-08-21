import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../providers/repository_providers.dart';
import '../controllers/payment_list_controller.dart';
import '../widgets/payment_tile.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../../../presentation/utils/sync_refresh_helper.dart';
import '../../../providers/user_lookup_provider.dart';

class PaymentListScreen extends ConsumerWidget {
  final String clientId;
  final String invoiceId;

  const PaymentListScreen({
    super.key,
    required this.clientId,
    required this.invoiceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceFuture = ref.read(invoiceRepositoryProvider).getById(invoiceId);
    final paymentState = ref.watch(paymentListProvider(invoiceId));

    return FutureBuilder(
      future: invoiceFuture,
      builder: (context, snapshot) {
        final invoiceResult = snapshot.data;
        final invoiceNumber = ((invoiceResult is Success) ? (invoiceResult as Success).value?.invoiceNumber.toString() : null) ?? '...';

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.paymentsInvoiceTitle(invoiceNumber)),
          ),
          body: paymentState.when(
            data: (payments) {
              final content = payments.isEmpty 
                  ? Expanded(
                      child: EmptyStateView(
                        message: AppLocalizations.of(context)!.noPaymentsRecorded,
                        icon: Icons.payments_outlined,
                        actionLabel: AppLocalizations.of(context)!.recordPayment,
                        onAction: () => context.push('/clients/$clientId/invoices/$invoiceId/payments/new'),
                      ),
                    )
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => SyncRefreshHelper.refresh(ref),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            return PaymentTile(
                              payment: payment,
                              onEdit: () => context.push('/clients/$clientId/invoices/$invoiceId/payments/${payment.id}'),
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => ConfirmDialog(
                                    title: AppLocalizations.of(context)!.deletePaymentTitle,
                                    content: AppLocalizations.of(context)!.deletePaymentConfirm,
                                    isDestructive: true,
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await PaymentDeleter.delete(ref, payment.id, invoiceId, clientId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(AppLocalizations.of(context)!.paymentDeleted), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                              onDeleteAttachment: (attachmentId) async {
                                try {
                                  await PaymentDeleter.deleteAttachment(ref, payment, attachmentId, invoiceId, clientId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppLocalizations.of(context)!.attachmentDeleted), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                    );

              return Column(
                children: [
                  if (invoiceResult is Success && (invoiceResult as Success).value != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((invoiceResult as Success).value!.createdBy != null)
                            _MetadataRow(label: 'Created by', uid: (invoiceResult as Success).value!.createdBy!),
                          if ((invoiceResult as Success).value!.updatedBy != null)
                            _MetadataRow(label: 'Last edited by', uid: (invoiceResult as Success).value!.updatedBy!),
                        ],
                      ),
                    ),
                  content,
                ],
              );
            },
            loading: () => LoadingView(message: AppLocalizations.of(context)!.loadingPayments),
            error: (error, _) => ErrorView(
              message: error.toString().localize(context),
              onRetry: () => ref.invalidate(paymentListProvider(invoiceId)),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/clients/$clientId/invoices/$invoiceId/payments/new'),
            child: const Icon(Icons.add),
          ),
        );
      }
    );
  }
}

class _MetadataRow extends ConsumerWidget {
  final String label;
  final String uid;

  const _MetadataRow({required this.label, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userLookupProvider(uid));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
          userAsync.when(
            data: (name) => Text(
              name,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
            ),
            loading: () => SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400)),
            error: (_, _) => Text('Unknown', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }
}
