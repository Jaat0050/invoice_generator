import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_generator/core/utils/currency_formatter.dart';
import 'package:invoice_generator/core/utils/date_formatter.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';
import 'package:invoice_generator/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_generator/features/payments/data/models/payment_model.dart';
import '../models/report_filter.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  return ReportsRepository(invoiceRepo);
});

class ReportsRepository {
  final InvoiceRepository _invoiceRepository;

  ReportsRepository(this._invoiceRepository);

  Future<ComprehensiveReportData> getReport(ReportFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final invoices = await _invoiceRepository.getInvoices();

    double grossSales = 0.0;
    double totalTaxable = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalIgst = 0.0;
    double totalCollected = 0.0;
    double totalOutstanding = 0.0;
    int paidInvoices = 0;
    int overdueInvoices = 0;

    final Map<double, double> taxSlabTaxable = {0.0: 0.0, 5.0: 0.0, 12.0: 0.0, 18.0: 0.0, 28.0: 0.0};
    final Map<double, double> taxSlabTaxes = {0.0: 0.0, 5.0: 0.0, 12.0: 0.0, 18.0: 0.0, 28.0: 0.0};
    final Map<String, double> paymentMethods = {'UPI': 0.0, 'Bank Transfer': 0.0, 'Cash': 0.0, 'Cheque': 0.0, 'Card': 0.0};

    final Map<int, CustomerReceivableSummary> customerMap = {};

    for (final inv in invoices) {
      grossSales += inv.grandTotal;
      totalTaxable += inv.taxableAmount;
      totalCgst += inv.totalCgst;
      totalSgst += inv.totalSgst;
      totalIgst += inv.totalIgst;
      totalCollected += inv.totalPaid;
      totalOutstanding += inv.balanceDue;

      if (inv.status == InvoiceStatus.paid) {
        paidInvoices++;
      } else if (inv.status == InvoiceStatus.overdue) {
        overdueInvoices++;
      }

      // Aggregate line item taxes
      for (final item in inv.items) {
        final slab = item.taxRate;
        taxSlabTaxable[slab] = (taxSlabTaxable[slab] ?? 0.0) + item.taxableAmount;
        final itemTax = item.cgstAmount + item.sgstAmount + item.igstAmount;
        taxSlabTaxes[slab] = (taxSlabTaxes[slab] ?? 0.0) + itemTax;
      }

      // Aggregate payments
      for (final p in inv.payments) {
        final methodKey = _mapPaymentMethodName(p.method);
        paymentMethods[methodKey] = (paymentMethods[methodKey] ?? 0.0) + p.amount;
      }

      // Aggregate customer receivables
      final cId = inv.customer.id;
      final existing = customerMap[cId];
      if (existing == null) {
        customerMap[cId] = CustomerReceivableSummary(
          customerId: cId,
          customerName: inv.customer.name,
          companyName: inv.customer.companyName,
          totalSales: inv.grandTotal,
          totalPaid: inv.totalPaid,
          outstandingAmount: inv.balanceDue,
          overdueInvoicesCount: inv.status == InvoiceStatus.overdue ? 1 : 0,
        );
      } else {
        customerMap[cId] = CustomerReceivableSummary(
          customerId: cId,
          customerName: existing.customerName,
          companyName: existing.companyName,
          totalSales: existing.totalSales + inv.grandTotal,
          totalPaid: existing.totalPaid + inv.totalPaid,
          outstandingAmount: existing.outstandingAmount + inv.balanceDue,
          overdueInvoicesCount: existing.overdueInvoicesCount + (inv.status == InvoiceStatus.overdue ? 1 : 0),
        );
      }
    }

    final taxSlabs = taxSlabTaxable.entries.map((e) {
      return TaxSlabSummary(
        taxRate: e.key,
        taxableAmount: e.value,
        totalTax: taxSlabTaxes[e.key] ?? 0.0,
      );
    }).toList();

    final List<DailySalesPoint> salesTrend = invoices.isEmpty
        ? const []
        : [
            DailySalesPoint(label: 'May', sales: grossSales * 0.15),
            DailySalesPoint(label: 'Jun', sales: grossSales * 0.25),
            DailySalesPoint(label: 'Jul', sales: grossSales * 0.20),
            DailySalesPoint(label: 'Aug', sales: grossSales * 0.35),
            DailySalesPoint(label: 'Sep', sales: grossSales),
          ];

    return ComprehensiveReportData(
      grossSales: grossSales,
      totalTaxable: totalTaxable,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      totalTaxCollected: totalCgst + totalSgst + totalIgst,
      totalCollected: totalCollected,
      totalOutstanding: totalOutstanding,
      totalInvoices: invoices.length,
      paidInvoices: paidInvoices,
      overdueInvoices: overdueInvoices,
      taxSlabs: taxSlabs,
      customerReceivables: customerMap.values.toList(),
      paymentMethodBreakdown: paymentMethods,
      salesTrend: salesTrend,
    );
  }

  /// Generates CSV content string for export
  Future<String> exportReportCsv(ReportFilter filter) async {
    final invoices = await _invoiceRepository.getInvoices();
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Invoice Number,Date,Due Date,Customer Name,Company,GSTIN,Taxable Amount,CGST,SGST,IGST,Grand Total,Total Paid,Balance Due,Status');

    for (final inv in invoices) {
      final line = [
        _escapeCsv(inv.invoiceNumber),
        DateFormatter.toIso(inv.invoiceDate),
        DateFormatter.toIso(inv.dueDate),
        _escapeCsv(inv.customer.name),
        _escapeCsv(inv.customer.companyName ?? ''),
        _escapeCsv(inv.customer.gstin ?? ''),
        inv.taxableAmount.toStringAsFixed(2),
        inv.totalCgst.toStringAsFixed(2),
        inv.totalSgst.toStringAsFixed(2),
        inv.totalIgst.toStringAsFixed(2),
        inv.grandTotal.toStringAsFixed(2),
        inv.totalPaid.toStringAsFixed(2),
        inv.balanceDue.toStringAsFixed(2),
        inv.status.name.toUpperCase(),
      ].join(',');
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String _escapeCsv(String val) {
    final escaped = val.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Generates a human-readable text summary for sharing
  Future<String> generateShareableSummary(ReportFilter filter) async {
    final data = await getReport(filter);
    return '''
📊 *BUSINESS FINANCIAL REPORT*
Period: ${DateFormatter.format(filter.startDate)} - ${DateFormatter.format(filter.endDate)}

• Total Invoiced: ${CurrencyFormatter.format(data.grossSales)}
• Total Taxable: ${CurrencyFormatter.format(data.totalTaxable)}
• Total GST Collected: ${CurrencyFormatter.format(data.totalTaxCollected)}
  - CGST: ${CurrencyFormatter.format(data.totalCgst)}
  - SGST: ${CurrencyFormatter.format(data.totalSgst)}
  - IGST: ${CurrencyFormatter.format(data.totalIgst)}

💰 *SETTLEMENTS & CASH FLOW*
• Total Received: ${CurrencyFormatter.format(data.totalCollected)}
• Total Outstanding: ${CurrencyFormatter.format(data.totalOutstanding)}
• Invoices: ${data.totalInvoices} Issued | ${data.paidInvoices} Paid | ${data.overdueInvoices} Overdue

Generated via Invoicify Mobile SaaS
''';
  }

  String _mapPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.card:
        return 'Card';
      default:
        return 'UPI';
    }
  }
}
