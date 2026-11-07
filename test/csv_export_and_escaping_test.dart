import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_item_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';
import 'package:invoice_generator/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_generator/features/reports/data/models/report_filter.dart';
import 'package:invoice_generator/features/reports/data/repositories/reports_repository.dart';

class _FakeInvoiceRepoWithEdgeCases extends InvoiceRepository {
  final List<InvoiceModel> _items;
  _FakeInvoiceRepoWithEdgeCases(this._items);

  @override
  Future<List<InvoiceModel>> getInvoices({InvoiceStatus? filterStatus}) async => _items;
}

void main() {
  group('ReportsRepository CSV RFC-4180 Escaping Tests', () {
    test('Properly escapes double quotes, commas, and special characters in CSV export', () async {
      final fakeRepo = _FakeInvoiceRepoWithEdgeCases([
        InvoiceModel(
          id: 1,
          businessId: 1,
          invoiceNumber: 'INV/2026/01,A',
          invoiceDate: DateTime(2026, 9, 1),
          dueDate: DateTime(2026, 9, 15),
          customer: const CustomerModel(
            id: 1,
            businessId: 1,
            name: 'John "The Boss" Doe',
            companyName: 'Acme, Inc. "Global"',
            phone: '+91 98765 43210',
            gstin: '27AABCA1234F1Z5',
          ),
          items: const [
            InvoiceItemModel(
              description: 'Standard Consulting',
              quantity: 1,
              rate: 10000.0,
              taxableAmount: 10000.0,
              taxRate: 18.0,
              cgstAmount: 900.0,
              sgstAmount: 900.0,
              totalAmount: 11800.0,
            ),
          ],
          subtotal: 10000.0,
          taxableAmount: 10000.0,
          totalCgst: 900.0,
          totalSgst: 900.0,
          grandTotal: 11800.0,
          totalPaid: 11800.0,
          balanceDue: 0.0,
          status: InvoiceStatus.paid,
        ),
      ]);

      final reportsRepo = ReportsRepository(fakeRepo);
      final filter = ReportFilter.fromPreset(ReportDateRangePreset.thisMonth);
      final csv = await reportsRepo.exportReportCsv(filter);

      // Verify that quotes inside names are doubled as per RFC-4180
      expect(csv.contains('"John ""The Boss"" Doe"'), true);
      expect(csv.contains('"Acme, Inc. ""Global"""'), true);
      expect(csv.contains('"INV/2026/01,A"'), true);
    });
  });
}

