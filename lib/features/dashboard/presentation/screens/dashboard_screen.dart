import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../customers/presentation/screens/customer_form_screen.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../data/models/dashboard_stats.dart';

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getDashboardStats();
});

final activeBusinessProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getActiveBusiness();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(activeBusinessProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: businessAsync.when(data: (business) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good day! 👋', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)), Text(business.name, style: AppTypography.headingMedium)]), loading: () => const Text('Loading...'), error: (_, __) => const Text('Invoicify Dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All systems active & up to date')));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statsAsync.when(
        data:
            (stats) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(activeBusinessProvider);
              },
              child: ResponsiveWrapper(
                maxWidth: 1080,
                child: ListView(
                  padding: AppDimensions.pagePadding,
                  children: [
                    // Hero Total Sales Card
                    _buildHeroSalesCard(stats),
                    const SizedBox(height: AppDimensions.md),

                    // Quick Action Buttons
                    _buildQuickActions(context),
                    const SizedBox(height: AppDimensions.md),

                    // KPI Row: Received & Pending
                    Row(
                      children: [
                        Expanded(child: KPICard(title: 'Received', amount: CurrencyFormatter.formatCompact(stats.totalPaid), subtitle: '${stats.paidInvoicesCount} Invoices Paid', icon: Icons.check_circle_outline_rounded, iconColor: AppColors.successDark)),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(child: KPICard(title: 'Pending', amount: CurrencyFormatter.formatCompact(stats.totalPending), subtitle: '${stats.unpaidInvoicesCount} Invoices Unpaid', icon: Icons.hourglass_top_rounded, iconColor: AppColors.warningDark)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Overdue Alert Banner if > 0
                    if (stats.totalOverdue > 0) ...[_buildOverdueAlertCard(context, stats), const SizedBox(height: AppDimensions.md)],

                    // Revenue Trend Chart
                    if (stats.revenueChartData.isNotEmpty) ...[_buildRevenueChartCard(stats.revenueChartData), const SizedBox(height: AppDimensions.md)],

                    // Recent Invoices Section Header
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recent Invoices', style: AppTypography.headingSmall), TextButton(onPressed: () => context.go('/invoices'), child: const Text('View All'))]),
                    const SizedBox(height: AppDimensions.sm),

                    // Recent Invoices List
                    if (stats.recentInvoices.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Center(child: Text('No invoices generated yet.'))) else ...stats.recentInvoices.map((inv) => _buildInvoiceTile(context, inv)),

                    const SizedBox(height: 80), // bottom nav spacing
                  ],
                ),
              ),
            ),
        loading:
            () => ListView(
              padding: AppDimensions.pagePadding,
              children: const [
                ShimmerLoader(width: double.infinity, height: 160),
                SizedBox(height: 16),
                Row(children: [Expanded(child: ShimmerLoader(width: double.infinity, height: 100)), SizedBox(width: 12), Expanded(child: ShimmerLoader(width: double.infinity, height: 100))]),
              ],
            ),
        error: (err, _) => Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text('Failed to load dashboard: $err'))),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionBtn(context, icon: Icons.add_circle_outline_rounded, label: 'New Invoice', color: AppColors.primary, onTap: () => context.push('/create-invoice'))),
        const SizedBox(width: 8),
        Expanded(child: _buildActionBtn(context, icon: Icons.person_add_alt_rounded, label: '+ Customer', color: const Color(0xFF0284C7), onTap: () => CustomerFormBottomSheet.show(context))),
        const SizedBox(width: 8),
        Expanded(child: _buildActionBtn(context, icon: Icons.inventory_2_outlined, label: 'Catalog', color: const Color(0xFF9333EA), onTap: () => context.push('/items'))),
        const SizedBox(width: 8),
        Expanded(child: _buildActionBtn(context, icon: Icons.bar_chart_rounded, label: 'Reports', color: const Color(0xFF059669), onTap: () => context.push('/reports'))),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppDimensions.roundedMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.roundedMd,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 22), const SizedBox(height: 4), Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)])),
      ),
    );
  }

  Widget _buildHeroSalesCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: AppDimensions.roundedXl, boxShadow: const [BoxShadow(color: Color(0x254F46E5), blurRadius: 16, offset: Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Revenue', style: AppTypography.labelLarge.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppDimensions.roundedFull), child: Text('This Fiscal Year', style: AppTypography.labelSmall.copyWith(color: Colors.white))),
            ],
          ),
          const SizedBox(height: 10),
          Text(CurrencyFormatter.format(stats.totalSales), style: AppTypography.currencyLarge.copyWith(color: Colors.white, fontSize: 32)),
          const SizedBox(height: 16),
          Row(children: [Icon(Icons.receipt_long_rounded, color: Colors.white.withValues(alpha: 0.8), size: 16), const SizedBox(width: 6), Text('${stats.totalInvoicesCount} Total Invoices Issued', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500))]),
        ],
      ),
    );
  }

  Widget _buildRevenueChartCard(List<MonthlyRevenue> trend) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Revenue Trajectory', style: AppTypography.headingSmall), Text('Monthly (₹)', style: AppTypography.bodySmall)]),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1000000,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.darkSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem('₹${(rod.toY / 1000).toStringAsFixed(0)}k', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < trend.length) {
                            return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(trend[idx].month, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11)));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups:
                      trend.asMap().entries.map((e) {
                        final isCurrent = e.key == trend.length - 1;
                        return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.revenue, gradient: isCurrent ? AppColors.primaryGradient : null, color: isCurrent ? null : AppColors.primaryLight.withValues(alpha: 0.6), width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueAlertCard(BuildContext context, DashboardStats stats) {
    return InkWell(
      onTap: () => context.push('/invoices'),
      borderRadius: AppDimensions.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: AppDimensions.roundedMd, border: Border.all(color: const Color(0xFFFECACA))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorDark, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${CurrencyFormatter.format(stats.totalOverdue)} Overdue', style: AppTypography.labelLarge.copyWith(color: AppColors.errorDark)), Text('${stats.overdueInvoicesCount} overdue invoices require payment reminders', style: AppTypography.bodySmall.copyWith(color: const Color(0xFF991B1B)))])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.errorDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceTile(BuildContext context, InvoiceModel invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/invoices/${invoice.id}'),
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(invoice.invoiceNumber, style: AppTypography.headingSmall.copyWith(fontSize: 15)), Text(CurrencyFormatter.format(invoice.grandTotal), style: AppTypography.currencyMedium.copyWith(fontSize: 15))]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(invoice.customer.companyName ?? invoice.customer.name, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormatter.format(invoice.invoiceDate), style: AppTypography.labelSmall), StatusBadge(status: _mapStatus(invoice.status))]),
          ],
        ),
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
