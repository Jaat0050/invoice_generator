import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../data/models/payment_model.dart';
import '../widgets/payment_receipt_dialog.dart';

class PaymentRecordItem {
  final PaymentModel payment;
  final InvoiceModel invoice;

  const PaymentRecordItem({required this.payment, required this.invoice});
}

class SelectedPaymentMethodFilterNotifier extends Notifier<PaymentMethod?> {
  @override
  PaymentMethod? build() => null;

  void setFilter(PaymentMethod? method) => state = method;
}

final selectedPaymentMethodFilterProvider =
    NotifierProvider<SelectedPaymentMethodFilterNotifier, PaymentMethod?>(SelectedPaymentMethodFilterNotifier.new);

final paymentHistoryProvider = FutureProvider.autoDispose<List<PaymentRecordItem>>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final filter = ref.watch(selectedPaymentMethodFilterProvider);
  final invoices = await invoiceRepo.getInvoices();

  final List<PaymentRecordItem> results = [];
  for (final inv in invoices) {
    for (final p in inv.payments) {
      if (filter == null || p.method == filter) {
        results.add(PaymentRecordItem(payment: p, invoice: inv));
      }
    }
  }

  // Sort descending by payment date
  results.sort((a, b) => b.payment.paymentDate.compareTo(a.payment.paymentDate));
  return results;
});

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentHistoryProvider);
    final selectedFilter = ref.watch(selectedPaymentMethodFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All Modes',
                  isSelected: selectedFilter == null,
                  onSelected: () => ref.read(selectedPaymentMethodFilterProvider.notifier).setFilter(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'UPI',
                  isSelected: selectedFilter == PaymentMethod.upi,
                  onSelected: () => ref.read(selectedPaymentMethodFilterProvider.notifier).setFilter(PaymentMethod.upi),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Bank Transfer',
                  isSelected: selectedFilter == PaymentMethod.bankTransfer,
                  onSelected: () => ref.read(selectedPaymentMethodFilterProvider.notifier).setFilter(PaymentMethod.bankTransfer),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Cash',
                  isSelected: selectedFilter == PaymentMethod.cash,
                  onSelected: () => ref.read(selectedPaymentMethodFilterProvider.notifier).setFilter(PaymentMethod.cash),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Cheque',
                  isSelected: selectedFilter == PaymentMethod.cheque,
                  onSelected: () => ref.read(selectedPaymentMethodFilterProvider.notifier).setFilter(PaymentMethod.cheque),
                ),
              ],
            ),
          ),
          const Divider(),

          // Payments List
          Expanded(
            child: paymentsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyStateView(
                    title: 'No Payments Recorded',
                    description: 'Payments recorded against invoices will appear in this ledger.',
                    icon: Icons.payments_outlined,
                    actionLabel: 'View Invoices',
                    onAction: () => context.go('/invoices'),
                  );
                }

                final totalSum = items.fold<double>(0.0, (sum, item) => sum + item.payment.amount);

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(paymentHistoryProvider),
                  child: ListView(
                    padding: AppDimensions.pagePadding,
                    children: [
                      // Total Received Card
                      KPICard(
                        title: 'Total Filtered Collections',
                        amount: CurrencyFormatter.format(totalSum),
                        subtitle: '${items.length} Transactions Settled',
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppColors.successDark,
                      ),
                      const SizedBox(height: 16),

                      ...items.map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onTap: () {
                              PaymentReceiptDialog.show(
                                context,
                                payment: item.payment,
                                invoiceNumber: item.invoice.invoiceNumber,
                                customerName: item.invoice.customer.companyName ?? item.invoice.customer.name,
                              );
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: AppDimensions.roundedMd,
                              ),
                              child: const Icon(Icons.check_rounded, color: AppColors.successDark, size: 20),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.invoice.customer.companyName ?? item.invoice.customer.name,
                                  style: AppTypography.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  CurrencyFormatter.format(item.payment.amount),
                                  style: AppTypography.currencyMedium.copyWith(fontSize: 15, color: AppColors.successDark),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Inv #${item.invoice.invoiceNumber}', style: AppTypography.bodySmall),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: AppDimensions.roundedSm,
                                      ),
                                      child: Text(
                                        item.payment.method.name.toUpperCase(),
                                        style: AppTypography.labelSmall.copyWith(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.format(item.payment.paymentDate),
                                  style: AppTypography.labelSmall,
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const ShimmerLoader(width: double.infinity, height: 90),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primaryLight : AppColors.border,
      ),
    );
  }
}
