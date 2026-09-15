import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../data/models/item_model.dart';
import '../../data/repositories/item_repository.dart';

class ItemSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

final itemSearchQueryProvider = NotifierProvider<ItemSearchQueryNotifier, String>(ItemSearchQueryNotifier.new);

final itemListProvider = FutureProvider.autoDispose<List<ItemModel>>((ref) async {
  final repo = ref.watch(itemRepositoryProvider);
  final query = ref.watch(itemSearchQueryProvider);
  return repo.getItems(searchQuery: query);
});

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Items & Services')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddItemModal(context, ref), icon: const Icon(Icons.add_rounded), backgroundColor: AppColors.primary, label: const Text('Add Item')),
      body: ResponsiveWrapper(
        maxWidth: 1000,
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: AppTextField(hint: 'Search by item name, HSN/SAC, or SKU...', prefixIcon: const Icon(Icons.search_rounded), onChanged: (val) => ref.read(itemSearchQueryProvider.notifier).setQuery(val))),
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyStateView(title: 'No Items in Catalog', description: 'Add products and consulting services to speed up invoice creation.', icon: Icons.inventory_2_outlined, actionLabel: '+ Add First Item', onAction: () => _showAddItemModal(context, ref));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildItemCard(context, item);
                    },
                  );
                },
                loading: () => ListView.separated(padding: const EdgeInsets.all(16.0), itemCount: 5, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, __) => const ShimmerLoader(width: double.infinity, height: 80)),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ItemModel item) {
    final isProduct = item.itemType == 'product';

    return Card(
      child: Padding(
        padding: AppDimensions.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isProduct ? AppColors.primaryContainer : const Color(0xFFF3E8FF), borderRadius: AppDimensions.roundedMd), child: Icon(isProduct ? Icons.devices_other_rounded : Icons.handshake_outlined, color: isProduct ? AppColors.primary : const Color(0xFF9333EA), size: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text('HSN/SAC: ${item.hsnSac ?? "N/A"} • ${item.unit}  |  GST ${item.taxRate.toInt()}%', style: AppTypography.bodySmall),
                  if (item.description != null) ...[const SizedBox(height: 4), Text(item.description!, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)],
                ],
              ),
            ),
            Text(CurrencyFormatter.format(item.rate), style: AppTypography.currencyMedium),
          ],
        ),
      ),
    );
  }

  void _showAddItemModal(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final hsnCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    String unit = 'PCS';
    double taxRate = 18.0;
    String itemType = 'product';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Add New Catalog Item', style: AppTypography.headingMedium),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Item / Service Name', hint: 'e.g. Graphic Design Retainer', controller: nameCtrl),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: AppTextField(label: 'HSN / SAC Code', hint: 'e.g. 998314', controller: hsnCtrl)), const SizedBox(width: 12), Expanded(child: AppTextField(label: 'Rate (₹)', hint: '0.00', keyboardType: TextInputType.number, controller: rateCtrl))]),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: taxRate,
                            decoration: const InputDecoration(labelText: 'GST Tax Slab'),
                            items: const [DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')), DropdownMenuItem(value: 5.0, child: Text('5%')), DropdownMenuItem(value: 12.0, child: Text('12%')), DropdownMenuItem(value: 18.0, child: Text('18% (Standard)')), DropdownMenuItem(value: 28.0, child: Text('28%'))],
                            onChanged: (v) {
                              if (v != null) setModalState(() => taxRate = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: unit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: const [DropdownMenuItem(value: 'PCS', child: Text('PCS')), DropdownMenuItem(value: 'NOS', child: Text('NOS')), DropdownMenuItem(value: 'HRS', child: Text('HRS')), DropdownMenuItem(value: 'BOX', child: Text('BOX')), DropdownMenuItem(value: 'KGS', child: Text('KGS')), DropdownMenuItem(value: 'MTR', child: Text('MTR'))],
                            onChanged: (v) {
                              if (v != null) setModalState(() => unit = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Save Item',
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final rate = double.tryParse(rateCtrl.text) ?? 0.0;

                        final repo = ref.read(itemRepositoryProvider);
                        await repo.addItem(ItemModel(id: 0, businessId: 1, name: nameCtrl.text.trim(), hsnSac: hsnCtrl.text.trim().isEmpty ? null : hsnCtrl.text.trim(), rate: rate, unit: unit, taxRate: taxRate, itemType: itemType));

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ref.invalidate(itemListProvider);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added to catalog!')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
