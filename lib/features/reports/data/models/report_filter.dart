enum ReportDateRangePreset {
  today,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisFiscalYear,
  custom,
}

class ReportFilter {
  final ReportDateRangePreset preset;
  final DateTime startDate;
  final DateTime endDate;

  const ReportFilter({
    this.preset = ReportDateRangePreset.thisMonth,
    required this.startDate,
    required this.endDate,
  });

  factory ReportFilter.fromPreset(ReportDateRangePreset preset) {
    final now = DateTime.now();
    switch (preset) {
      case ReportDateRangePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        return ReportFilter(preset: preset, startDate: start, endDate: now);
      case ReportDateRangePreset.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return ReportFilter(preset: preset, startDate: DateTime(start.year, start.month, start.day), endDate: now);
      case ReportDateRangePreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return ReportFilter(preset: preset, startDate: start, endDate: now);
      case ReportDateRangePreset.thisQuarter:
        final currentQuarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(now.year, currentQuarterMonth, 1);
        return ReportFilter(preset: preset, startDate: start, endDate: now);
      case ReportDateRangePreset.thisFiscalYear:
        // Indian FY starts April 1st
        final fyYear = now.month >= 4 ? now.year : now.year - 1;
        final start = DateTime(fyYear, 4, 1);
        return ReportFilter(preset: preset, startDate: start, endDate: now);
      case ReportDateRangePreset.custom:
        return ReportFilter(
          preset: preset,
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
        );
    }
  }

  ReportFilter copyWith({
    ReportDateRangePreset? preset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportFilter(
      preset: preset ?? this.preset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class TaxSlabSummary {
  final double taxRate; // 0, 5, 12, 18, 28
  final double taxableAmount;
  final double totalTax;

  const TaxSlabSummary({
    required this.taxRate,
    required this.taxableAmount,
    required this.totalTax,
  });
}

class CustomerReceivableSummary {
  final int customerId;
  final String customerName;
  final String? companyName;
  final double totalSales;
  final double totalPaid;
  final double outstandingAmount;
  final int overdueInvoicesCount;

  const CustomerReceivableSummary({
    required this.customerId,
    required this.customerName,
    this.companyName,
    required this.totalSales,
    required this.totalPaid,
    required this.outstandingAmount,
    this.overdueInvoicesCount = 0,
  });
}

class ComprehensiveReportData {
  final double grossSales;
  final double totalTaxable;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalTaxCollected;
  final double totalCollected;
  final double totalOutstanding;
  final int totalInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final List<TaxSlabSummary> taxSlabs;
  final List<CustomerReceivableSummary> customerReceivables;
  final Map<String, double> paymentMethodBreakdown;
  final List<DailySalesPoint> salesTrend;

  const ComprehensiveReportData({
    required this.grossSales,
    required this.totalTaxable,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalTaxCollected,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.totalInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.taxSlabs,
    required this.customerReceivables,
    required this.paymentMethodBreakdown,
    required this.salesTrend,
  });
}

class DailySalesPoint {
  final String label; // e.g. "Mon", "10 Sep"
  final double sales;

  const DailySalesPoint({required this.label, required this.sales});
}
