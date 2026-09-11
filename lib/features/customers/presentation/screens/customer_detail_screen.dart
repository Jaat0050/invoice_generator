import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

final customerDetailProvider = FutureProvider.autoDispose.family<CustomerModel, int>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerById(id);
});

final customerInvoicesProvider = FutureProvider.autoDispose.family<List<InvoiceModel>, int>((ref, customerId) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  final all = await repo.getInvoices();
  return all.where((inv) => inv.customer.id == customerId).toList();
});

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Account Statement',
            onPressed: () {
              if (customerAsync.hasValue) {
                final c = customerAsync.value!;
                final statement = '''
📄 *ACCOUNT STATEMENT FOR ${c.companyName ?? c.name}*
Total Billed: ${CurrencyFormatter.format(c.totalSales)}
Total Paid: ${CurrencyFormatter.format(c.totalPaid)}
Outstanding Balance Due: ${CurrencyFormatter.format(c.outstandingAmount)}

Please settle the pending balance at your earliest convenience.
''';
                SharePlus.instance.share(
                  ShareParams(text: statement, subject: 'Statement for ${c.name}'),
                );
              }
            },
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) => ListView(
          padding: AppDimensions.pagePadding,
          children: [
            // Profile Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryContainer,
                          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.companyName ?? customer.name,
                                style: AppTypography.headingSmall,
                              ),
                              if (customer.companyName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Contact: ${customer.name}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                '${customer.phone} ${customer.email != null ? "• ${customer.email}" : ""}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (customer.gstin != null) ...[
                      Text('GSTIN: ${customer.gstin}', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                    ],
                    if (customer.billingAddress != null) ...[
                      Text(
                        'Address: ${customer.billingAddress!}, ${customer.billingCity ?? ""}, ${customer.billingState} (Code: ${customer.billingStateCode ?? ""})',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Financial Balance KPIs
            Row(
              children: [
                Expanded(
                  child: KPICard(
                    title: 'Total Billed',
                    amount: CurrencyFormatter.formatCompact(customer.totalSales),
                    subtitle: 'Lifetime sales',
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: KPICard(
                    title: 'Outstanding',
                    amount: CurrencyFormatter.formatCompact(customer.outstandingAmount),
                    subtitle: customer.outstandingAmount > 0 ? 'Pending' : 'Settled',
                    icon: Icons.warning_amber_rounded,
                    iconColor: customer.outstandingAmount > 0 ? AppColors.errorDark : AppColors.successDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Create Invoice CTA
            AppButton(
              label: 'Create Invoice for this Customer',
              icon: Icons.add_rounded,
              onPressed: () => context.push('/create-invoice'),
            ),
            const SizedBox(height: AppDimensions.xl),

            // Invoices History
            Text('Invoice History', style: AppTypography.headingSmall),
            const SizedBox(height: 10),

            invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('No invoices recorded for this customer yet.')),
                  );
                }

                return Column(
                  children: invoices.map((inv) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () => context.push('/invoices/${inv.id}'),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(inv.invoiceNumber, style: AppTypography.labelLarge),
                            Text(CurrencyFormatter.format(inv.grandTotal), style: AppTypography.currencyMedium.copyWith(fontSize: 15)),
                          ],
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Due: ${DateFormatter.format(inv.dueDate)}', style: AppTypography.bodySmall),
                            StatusBadge(status: _mapStatus(inv.status)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading invoices: $err'),
            ),
            const SizedBox(height: 40),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading customer: $err')),
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
