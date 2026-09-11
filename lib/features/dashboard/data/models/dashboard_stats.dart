import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';

class DashboardStats {
  final double totalSales;
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final int totalInvoicesCount;
  final int paidInvoicesCount;
  final int unpaidInvoicesCount;
  final int overdueInvoicesCount;
  final List<InvoiceModel> recentInvoices;
  final List<MonthlyRevenue> revenueChartData;

  const DashboardStats({
    this.totalSales = 0.0,
    this.totalPaid = 0.0,
    this.totalPending = 0.0,
    this.totalOverdue = 0.0,
    this.totalInvoicesCount = 0,
    this.paidInvoicesCount = 0,
    this.unpaidInvoicesCount = 0,
    this.overdueInvoicesCount = 0,
    this.recentInvoices = const [],
    this.revenueChartData = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0.0,
      totalOverdue: (json['total_overdue'] as num?)?.toDouble() ?? 0.0,
      totalInvoicesCount: (json['total_invoices_count'] as int?) ?? 0,
      paidInvoicesCount: (json['paid_invoices_count'] as int?) ?? 0,
      unpaidInvoicesCount: (json['unpaid_invoices_count'] as int?) ?? 0,
      overdueInvoicesCount: (json['overdue_invoices_count'] as int?) ?? 0,
      recentInvoices: (json['recent_invoices'] as List<dynamic>?)
              ?.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      revenueChartData: (json['revenue_chart'] as List<dynamic>?)
              ?.map((e) => MonthlyRevenue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MonthlyRevenue {
  final String month;
  final double revenue;

  const MonthlyRevenue({required this.month, required this.revenue});

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month'] as String,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}
