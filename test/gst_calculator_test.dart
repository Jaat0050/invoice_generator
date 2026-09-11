import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/core/utils/currency_formatter.dart';
import 'package:invoice_generator/core/utils/gst_calculator.dart';
import 'package:invoice_generator/core/utils/number_to_words.dart';
import 'package:invoice_generator/features/auth/data/models/business_model.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_item_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';
import 'package:invoice_generator/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_generator/features/invoices/utils/pdf_invoice_generator.dart';
import 'package:invoice_generator/features/reports/data/models/report_filter.dart';
import 'package:invoice_generator/features/reports/data/repositories/reports_repository.dart';
import 'package:invoice_generator/features/templates/data/models/template_config_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GstCalculator Tests', () {
    test('Calculates Intra-State Line Item (CGST 9% + SGST 9%) correctly', () {
      final calc = GstCalculator.calculateLineItem(
        quantity: 2,
        rate: 50000,
        discountPercent: 10,
        taxRate: 18,
        supplyType: GstSupplyType.intraState,
      );

      expect(calc.grossAmount, 100000.0);
      expect(calc.discountAmount, 10000.0);
      expect(calc.taxableAmount, 90000.0);
      expect(calc.cgstAmount, 8100.0);
      expect(calc.sgstAmount, 8100.0);
      expect(calc.igstAmount, 0.0);
      expect(calc.totalAmount, 106200.0);
    });

    test('Calculates Inter-State Line Item (IGST 18%) correctly', () {
      final calc = GstCalculator.calculateLineItem(
        quantity: 1,
        rate: 100000,
        discountPercent: 0,
        taxRate: 18,
        supplyType: GstSupplyType.interState,
      );

      expect(calc.taxableAmount, 100000.0);
      expect(calc.cgstAmount, 0.0);
      expect(calc.sgstAmount, 0.0);
      expect(calc.igstAmount, 18000.0);
      expect(calc.totalAmount, 118000.0);
    });

    test('Calculates Invoice Totals with Round Off and Balance Due', () {
      final item1 = GstCalculator.calculateLineItem(
        quantity: 1,
        rate: 54999,
        taxRate: 18,
        supplyType: GstSupplyType.interState,
      );

      final totals = GstCalculator.calculateInvoiceTotals(
        items: [item1],
        totalPaid: 50000,
      );

      expect(totals.grandTotal, 64899.0);
      expect((totals.roundOff * 100).round() / 100, 0.18);
      expect(totals.balanceDue, 14899.0);
    });
  });

  group('CurrencyFormatter & NumberToWords Tests', () {
    test('Formats Lakhs and Crores into standard Indian numbering', () {
      expect(CurrencyFormatter.format(100000), '₹1,00,000.00');
      expect(CurrencyFormatter.format(1250000), '₹12,50,000.00');
    });

    test('Formats Compact representations', () {
      expect(CurrencyFormatter.formatCompact(1250000), '₹12.50 L');
      expect(CurrencyFormatter.formatCompact(15000000), '₹1.50 Cr');
    });

    test('Converts amounts to Indian Rupee words', () {
      expect(
        NumberToWords.convertToIndianRupees(125000),
        'Rupees One Lakh Twenty-Five Thousand Only',
      );
      expect(
        NumberToWords.convertToIndianRupees(589764),
        'Rupees Five Lakh Eighty-Nine Thousand Seven Hundred Sixty-Four Only',
      );
    });
  });

  group('PdfInvoiceGenerator Tests', () {
    test('Generates valid non-empty PDF bytes for tax invoice', () async {
      const business = BusinessModel(
        id: 1,
        name: 'Apex Solutions Pvt Ltd',
        gstin: '27AABCA1234F1Z5',
        phone: '+91 98765 43210',
        email: 'billing@apex.com',
        upiId: 'apex@icici',
      );

      final invoice = InvoiceModel(
        id: 1,
        businessId: 1,
        invoiceNumber: 'INV-1001',
        invoiceDate: DateTime(2026, 9, 10),
        dueDate: DateTime(2026, 9, 25),
        customer: const CustomerModel(
          id: 1,
          businessId: 1,
          name: 'Rahul Verma',
          companyName: 'ABC Enterprises Pvt Ltd',
          phone: '+91 98220 12345',
          billingState: 'Maharashtra',
        ),
        items: const [
          InvoiceItemModel(
            description: 'MacBook Pro 16" M3 Max',
            hsnSac: '84713010',
            quantity: 1,
            rate: 249900.0,
            taxableAmount: 249900.0,
            taxRate: 18.0,
            cgstAmount: 22491.0,
            sgstAmount: 22491.0,
            totalAmount: 294882.0,
          ),
        ],
        subtotal: 249900.0,
        taxableAmount: 249900.0,
        totalCgst: 22491.0,
        totalSgst: 22491.0,
        grandTotal: 294882.0,
        balanceDue: 294882.0,
      );

      final bytes = await PdfInvoiceGenerator.generatePdf(
        invoice: invoice,
        business: business,
        config: const TemplateConfigModel(),
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, true);
    });
  });

  group('ReportsRepository Tests', () {
    test('Generates comprehensive report and CSV export', () async {
      final invoiceRepo = InvoiceRepository();
      final reportsRepo = ReportsRepository(invoiceRepo);
      final filter = ReportFilter.fromPreset(ReportDateRangePreset.thisMonth);

      final report = await reportsRepo.getReport(filter);
      expect(report.grossSales, greaterThan(0));
      expect(report.totalTaxCollected, greaterThan(0));
      expect(report.customerReceivables.isNotEmpty, true);

      final csv = await reportsRepo.exportReportCsv(filter);
      expect(csv.contains('Invoice Number,Date,Due Date'), true);
      expect(csv.contains('INV-1001'), true);

      final summary = await reportsRepo.generateShareableSummary(filter);
      expect(summary.contains('BUSINESS FINANCIAL REPORT'), true);
    });
  });
}
