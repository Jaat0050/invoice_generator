import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../data/models/report_filter.dart';
import '../../data/repositories/reports_repository.dart';

class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => ReportFilter.fromPreset(ReportDateRangePreset.thisMonth);

  void setPreset(ReportDateRangePreset preset) => state = ReportFilter.fromPreset(preset);
  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(preset: ReportDateRangePreset.custom, startDate: start, endDate: end);
  }
}

final reportFilterProvider =
    NotifierProvider<ReportFilterNotifier, ReportFilter>(ReportFilterNotifier.new);

final reportDataProvider = FutureProvider.autoDispose<ComprehensiveReportData>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getReport(filter);
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final reportAsync = ref.watch(reportDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Financial Summary',
            onPressed: () async {
              final repo = ref.read(reportsRepositoryProvider);
              final summaryText = await repo.generateShareableSummary(filter);
              SharePlus.instance.share(
                ShareParams(text: summaryText, subject: 'Business Financial Summary'),
              );
            },
          ),
        ],
      ),
      body: ResponsiveWrapper(
        maxWidth: 1000,
        child: ListView(
        padding: AppDimensions.pagePadding,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip(
                  context,
                  ref,
                  label: 'This Month',
                  isSelected: filter.preset == ReportDateRangePreset.thisMonth,
                  preset: ReportDateRangePreset.thisMonth,
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  context,
                  ref,
                  label: 'This Week',
                  isSelected: filter.preset == ReportDateRangePreset.thisWeek,
                  preset: ReportDateRangePreset.thisWeek,
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  context,
                  ref,
                  label: 'Fiscal Year',
                  isSelected: filter.preset == ReportDateRangePreset.thisFiscalYear,
                  preset: ReportDateRangePreset.thisFiscalYear,
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  context,
                  ref,
                  label: 'This Quarter',
                  isSelected: filter.preset == ReportDateRangePreset.thisQuarter,
                  preset: ReportDateRangePreset.thisQuarter,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Date Interval Indicator
          Text(
            'Showing data from ${DateFormatter.format(filter.startDate)} to ${DateFormatter.format(filter.endDate)}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.lg),

          reportAsync.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Grid
                Row(
                  children: [
                    Expanded(
                      child: KPICard(
                        title: 'Total Invoiced',
                        amount: CurrencyFormatter.formatCompact(data.grossSales),
                        subtitle: '${data.totalInvoices} Invoices',
                        icon: Icons.receipt_long_rounded,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: KPICard(
                        title: 'GST Collected',
                        amount: CurrencyFormatter.formatCompact(data.totalTaxCollected),
                        subtitle: 'Tax liability',
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  children: [
                    Expanded(
                      child: KPICard(
                        title: 'Received',
                        amount: CurrencyFormatter.formatCompact(data.totalCollected),
                        subtitle: '${data.paidInvoices} Fully Paid',
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.successDark,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: KPICard(
                        title: 'Outstanding',
                        amount: CurrencyFormatter.formatCompact(data.totalOutstanding),
                        subtitle: '${data.overdueInvoices} Overdue',
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.errorDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),

                // Interactive Sales Bar Chart
                _buildChartSection(data),
                const SizedBox(height: AppDimensions.xl),

                // GST Tax Breakdown Card
                _buildTaxBreakdownCard(data),
                const SizedBox(height: AppDimensions.xl),

                // Customer Receivables List
                _buildCustomerReceivablesSection(data),
                const SizedBox(height: AppDimensions.xl),

                // Export Button
                AppButton(
                  label: 'Export Invoices to CSV (Excel)',
                  icon: Icons.download_rounded,
                  variant: ButtonVariant.outline,
                  onPressed: () async {
                    final repo = ref.read(reportsRepositoryProvider);
                    final csv = await repo.exportReportCsv(filter);
                    SharePlus.instance.share(
                      ShareParams(
                        text: csv,
                        subject: 'Invoice_Report_${DateFormatter.toIso(DateTime.now())}.csv',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
            loading: () => const Column(
              children: [
                ShimmerLoader(width: double.infinity, height: 110),
                SizedBox(height: 16),
                ShimmerLoader(width: double.infinity, height: 220),
              ],
            ),
            error: (err, _) => Center(child: Text('Error loading report: $err')),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDateChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool isSelected,
    required ReportDateRangePreset preset,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(reportFilterProvider.notifier).setPreset(preset),
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

  Widget _buildChartSection(ComprehensiveReportData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Revenue Trend', style: AppTypography.headingSmall),
                Text('Last 5 Months', style: AppTypography.bodySmall),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1000000,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.darkSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '₹${(rod.toY / 1000).toStringAsFixed(0)}k',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
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
                          if (idx >= 0 && idx < data.salesTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data.salesTrend[idx].label,
                                style: AppTypography.labelSmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: data.salesTrend.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pt = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: pt.sales,
                          gradient: AppColors.primaryGradient,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxBreakdownCard(ComprehensiveReportData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GST Tax Breakdown Summary', style: AppTypography.headingSmall),
            const SizedBox(height: 12),
            _buildTaxRow('Gross Taxable Value', CurrencyFormatter.format(data.totalTaxable), isBold: false),
            const Divider(height: 16),
            _buildTaxRow('CGST (Central Tax)', CurrencyFormatter.format(data.totalCgst)),
            _buildTaxRow('SGST (State Tax)', CurrencyFormatter.format(data.totalSgst)),
            _buildTaxRow('IGST (Integrated Tax)', CurrencyFormatter.format(data.totalIgst)),
            const Divider(height: 16),
            _buildTaxRow(
              'Total GST Liability',
              CurrencyFormatter.format(data.totalTaxCollected),
              isBold: true,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: AppTypography.currencyMedium.copyWith(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReceivablesSection(ComprehensiveReportData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Receivables Aging', style: AppTypography.headingSmall),
            const SizedBox(height: 12),
            ...data.customerReceivables.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.companyName ?? c.customerName, style: AppTypography.labelLarge),
                          Text('Billed: ${CurrencyFormatter.format(c.totalSales)}', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(c.outstandingAmount),
                          style: AppTypography.currencyMedium.copyWith(
                            fontSize: 14,
                            color: c.outstandingAmount > 0 ? AppColors.error : AppColors.successDark,
                          ),
                        ),
                        Text(
                          c.outstandingAmount > 0 ? '${c.overdueInvoicesCount} overdue' : 'Settled',
                          style: AppTypography.labelSmall.copyWith(
                            color: c.outstandingAmount > 0 ? AppColors.errorDark : AppColors.successDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
