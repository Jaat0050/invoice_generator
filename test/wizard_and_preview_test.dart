import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/dashboard/data/models/dashboard_stats.dart';
import 'package:invoice_generator/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_item_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';
import 'package:invoice_generator/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_generator/features/invoices/presentation/screens/create_invoice_wizard_screen.dart';
import 'package:invoice_generator/features/invoices/presentation/screens/invoice_detail_screen.dart';

void main() {
  group('Core MVP Screens Tests', () {
    testWidgets('DashboardScreen renders KPIs, Quick Actions, and Recent Invoices', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceRepositoryProvider.overrideWithValue(_TestInvoiceRepository(null)),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('New Invoice'), findsOneWidget);
      expect(find.text('Catalog'), findsOneWidget);
      expect(find.text('Recent Invoices'), findsOneWidget);
    });

    testWidgets('CreateInvoiceWizardScreen renders Stepper with 4 steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateInvoiceWizardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Create GST Invoice'), findsOneWidget);
      expect(find.text('Invoice Number'), findsOneWidget);
      expect(find.text('Quick Payment Terms'), findsOneWidget);
    });

    testWidgets('InvoiceDetailScreen renders invoice totals and Record Payment CTA', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testInvoice = InvoiceModel(
        id: 1,
        businessId: 1,
        invoiceNumber: 'INV-1001',
        invoiceDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        customer: const CustomerModel(
          id: 1,
          businessId: 1,
          name: 'Test Customer',
          phone: '+91 98765 43210',
        ),
        items: const [
          InvoiceItemModel(
            description: 'Item A',
            quantity: 1,
            rate: 1000.0,
            taxableAmount: 1000.0,
            taxRate: 18.0,
            cgstAmount: 90.0,
            sgstAmount: 90.0,
            totalAmount: 1180.0,
          ),
        ],
        subtotal: 1000.0,
        taxableAmount: 1000.0,
        totalCgst: 90.0,
        totalSgst: 90.0,
        grandTotal: 1180.0,
        totalPaid: 0.0,
        balanceDue: 1180.0,
        status: InvoiceStatus.unpaid,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceRepositoryProvider.overrideWithValue(_TestInvoiceRepository(testInvoice)),
          ],
          child: const MaterialApp(
            home: InvoiceDetailScreen(invoiceId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Grand Total'), findsOneWidget);
      expect(find.text('Balance Due'), findsOneWidget);
      expect(find.text('Billed To'), findsOneWidget);
      expect(find.text('Line Items'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('View / Download PDF'), findsOneWidget);
    });
  });
}

class _TestInvoiceRepository extends InvoiceRepository {
  final InvoiceModel? _sample;
  _TestInvoiceRepository(this._sample);

  @override
  Future<InvoiceModel> getInvoiceById(int id) async => _sample!;

  @override
  Future<DashboardStats> getDashboardStats() async {
    return const DashboardStats(
      totalSales: 25000.0,
      totalPaid: 20000.0,
      totalPending: 5000.0,
      totalOverdue: 0.0,
      totalInvoicesCount: 5,
      paidInvoicesCount: 4,
      unpaidInvoicesCount: 1,
      overdueInvoicesCount: 0,
      recentInvoices: [],
      revenueChartData: [],
    );
  }
}
