import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../payments/presentation/widgets/record_payment_bottom_sheet.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';

final invoiceDetailProvider = FutureProvider.autoDispose.family<InvoiceModel, int>((ref, id) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getInvoiceById(id);
});

class InvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invoice #$invoiceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'View PDF Preview',
            onPressed: () => context.push('/invoices/$invoiceId/preview'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: invoiceAsync.when(
        data: (invoice) => ResponsiveWrapper(
          maxWidth: 860,
          child: ListView(
          padding: AppDimensions.pagePadding,
          children: [
            // Status & Total Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: AppTypography.headingLarge,
                        ),
                        StatusBadge(status: _mapStatus(invoice.status)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Grand Total', style: AppTypography.bodySmall),
                            Text(
                              CurrencyFormatter.format(invoice.grandTotal),
                              style: AppTypography.currencyLarge.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Balance Due', style: AppTypography.bodySmall),
                            Text(
                              CurrencyFormatter.format(invoice.balanceDue),
                              style: AppTypography.currencyLarge.copyWith(
                                color: invoice.balanceDue > 0 ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Invoice Date: ${DateFormatter.format(invoice.invoiceDate)}', style: AppTypography.labelSmall),
                        Text('Due: ${DateFormatter.format(invoice.dueDate)}', style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Customer Bill To
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billed To', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(
                      invoice.customer.companyName ?? invoice.customer.name,
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invoice.customer.billingAddress ?? ""}\n${invoice.customer.billingCity ?? ""}, ${invoice.customer.billingState}',
                      style: AppTypography.bodySmall,
                    ),
                    if (invoice.customer.gstin != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'GSTIN: ${invoice.customer.gstin}',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Line Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Line Items', style: AppTypography.headingSmall),
                    const SizedBox(height: 12),
                    ...invoice.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description, style: AppTypography.labelLarge),
                                  Text(
                                    '${item.quantity.toInt()} × ${CurrencyFormatter.format(item.rate)}  |  GST ${item.taxRate.toInt()}%',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.totalAmount),
                              style: AppTypography.labelLarge,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            if (invoice.balanceDue > 0) ...[
              AppButton(
                label: 'Record Payment',
                icon: Icons.payments_outlined,
                onPressed: () => RecordPaymentBottomSheet.show(context, invoice),
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'View / Download PDF',
              variant: ButtonVariant.outline,
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () => context.push('/invoices/$invoiceId/preview'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading invoice: $err')),
      ),
    );
  }

  InvoiceStatusType _mapStatus(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return InvoiceStatusType.paid;
      case InvoiceStatus.partiallyPaid:
        return InvoiceStatusType.partiallyPaid;
      case InvoiceStatus.unpaid:
        return InvoiceStatusType.unpaid;
      case InvoiceStatus.overdue:
        return InvoiceStatusType.overdue;
      case InvoiceStatus.draft:
        return InvoiceStatusType.draft;
      case InvoiceStatus.cancelled:
        return InvoiceStatusType.cancelled;
    }
  }
}
