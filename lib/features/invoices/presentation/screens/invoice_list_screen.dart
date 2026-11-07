import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import 'invoice_detail_screen.dart';

class SelectedFilterStatusNotifier extends Notifier<InvoiceStatus?> {
  @override
  InvoiceStatus? build() => null;

  void setFilter(InvoiceStatus? status) => state = status;
}

final selectedFilterStatusProvider =
    NotifierProvider<SelectedFilterStatusNotifier, InvoiceStatus?>(SelectedFilterStatusNotifier.new);

final invoiceListProvider = FutureProvider.autoDispose<List<InvoiceModel>>((ref) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  final filter = ref.watch(selectedFilterStatusProvider);
  return repo.getInvoices(filterStatus: filter);
});

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceListProvider);
    final currentFilter = ref.watch(selectedFilterStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveWrapper(
        maxWidth: 1000,
        child: Column(
          children: [
            // Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'All',
                    isSelected: currentFilter == null,
                    onSelected: () => ref.read(selectedFilterStatusProvider.notifier).setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Unpaid',
                    isSelected: currentFilter == InvoiceStatus.unpaid,
                    onSelected: () => ref.read(selectedFilterStatusProvider.notifier).setFilter(InvoiceStatus.unpaid),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Partial',
                    isSelected: currentFilter == InvoiceStatus.partiallyPaid,
                    onSelected: () => ref.read(selectedFilterStatusProvider.notifier).setFilter(InvoiceStatus.partiallyPaid),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Paid',
                    isSelected: currentFilter == InvoiceStatus.paid,
                    onSelected: () => ref.read(selectedFilterStatusProvider.notifier).setFilter(InvoiceStatus.paid),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Overdue',
                    isSelected: currentFilter == InvoiceStatus.overdue,
                    onSelected: () => ref.read(selectedFilterStatusProvider.notifier).setFilter(InvoiceStatus.overdue),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Draft',
                    isSelected: currentFilter == InvoiceStatus.draft,
                    onSelected: () => ref.read(selectedFilterStatusProvider.notifier).setFilter(InvoiceStatus.draft),
                  ),
                ],
              ),
            ),

            // Invoices List
            Expanded(
              child: invoicesAsync.when(
                data: (invoices) {
                  final filtered = currentFilter == null
                      ? invoices
                      : invoices.where((i) => i.status == currentFilter).toList();

                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      title: 'No Invoices Found',
                      description: currentFilter == null
                          ? 'Create your first GST invoice in seconds.'
                          : 'No invoices match the selected status filter.',
                      icon: Icons.receipt_long_outlined,
                      actionLabel: currentFilter == null ? '+ Create Invoice' : null,
                      onAction: currentFilter == null ? () => context.push('/create-invoice') : null,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final invoice = filtered[index];
                      return _buildInvoiceCard(context, ref, invoice);
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const ShimmerLoader(width: double.infinity, height: 100),
                ),
                error: (err, _) => Center(child: Text('Error loading invoices: $err')),
              ),
            ),
          ],
        ),
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

  Widget _buildInvoiceCard(BuildContext context, WidgetRef ref, InvoiceModel invoice) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/invoices/${invoice.id}'),
        borderRadius: AppDimensions.roundedLg,
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: invoice.isGst ? AppColors.primaryContainer : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          invoice.isGst ? 'GST' : 'NON-GST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: invoice.isGst ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(invoice.grandTotal),
                        style: AppTypography.currencyMedium,
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        onSelected: (action) {
                          if (action == 'view') {
                            context.push('/invoices/${invoice.id}');
                          } else if (action == 'preview') {
                            context.push('/invoices/${invoice.id}/preview');
                          } else if (action == 'delete') {
                            _confirmDeleteInvoice(context, ref, invoice);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'preview',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('PDF & Share'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                invoice.customer.companyName ?? invoice.customer.name,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.dueDate != null ? 'Due: ${DateFormatter.format(invoice.dueDate)}' : 'Invoice: ${DateFormatter.format(invoice.invoiceDate)}',
                    style: AppTypography.bodySmall,
                  ),
                  StatusBadge(status: _mapStatus(invoice.status)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteInvoice(BuildContext context, WidgetRef ref, InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Invoice?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete invoice ${invoice.invoiceNumber}?\n\nThis will remove all associated line items and payment records. This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(invoiceRepositoryProvider).deleteInvoice(invoice.id);
        ref.invalidate(invoiceListProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(invoiceDetailProvider(invoice.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice ${invoice.invoiceNumber} deleted successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete invoice: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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
