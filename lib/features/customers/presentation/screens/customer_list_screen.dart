import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_form_screen.dart';

class CustomerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final customerSearchQueryProvider = NotifierProvider<CustomerSearchQueryNotifier, String>(CustomerSearchQueryNotifier.new);

final customerListProvider = FutureProvider.autoDispose<List<CustomerModel>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchQueryProvider);
  return repo.getCustomers(searchQuery: query);
});

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await CustomerFormBottomSheet.show(context);
          if (added != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer ${added.name} added!')));
          }
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        backgroundColor: AppColors.primary,
        label: const Text('Add Customer'),
      ),
      body: ResponsiveWrapper(
        maxWidth: 1000,
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: AppTextField(hint: 'Search by name, company, or phone...', prefixIcon: const Icon(Icons.search_rounded), onChanged: (val) => ref.read(customerSearchQueryProvider.notifier).setQuery(val))),
            Expanded(
              child: customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return EmptyStateView(title: 'No Customers Found', description: 'Add your first customer to quickly generate GST invoices.', icon: Icons.people_outline_rounded, actionLabel: '+ Add Customer', onAction: () => CustomerFormBottomSheet.show(context));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(context, customer);
                    },
                  );
                },
                loading: () => ListView.separated(padding: const EdgeInsets.all(16.0), itemCount: 4, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, __) => const ShimmerLoader(width: double.infinity, height: 90)),
                error: (err, _) => Center(child: Text('Error loading customers: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel customer) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/customers/${customer.id}'),
        borderRadius: AppDimensions.roundedLg,
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(customer.companyName ?? customer.name, style: AppTypography.headingSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (customer.outstandingAmount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: AppDimensions.roundedSm), child: Text('Due: ${CurrencyFormatter.format(customer.outstandingAmount)}', style: AppTypography.labelSmall.copyWith(color: AppColors.errorDark, fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 4),
              Text('${customer.name} • ${customer.phone}', style: AppTypography.bodySmall),
              if (customer.gstin != null) ...[const SizedBox(height: 4), Text('GSTIN: ${customer.gstin}', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted))],
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Sales: ${CurrencyFormatter.format(customer.totalSales)}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)), Text('${customer.billingCity ?? ""}, ${customer.billingState}', style: AppTypography.labelSmall)]),
            ],
          ),
        ),
      ),
    );
  }
}
