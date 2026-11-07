import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_item_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';
import 'package:invoice_generator/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_generator/features/payments/data/models/payment_model.dart';
import 'package:invoice_generator/features/payments/presentation/widgets/record_payment_bottom_sheet.dart';

class _FakeInvoiceRepoForPayment extends InvoiceRepository {
  InvoiceModel invoice;
  _FakeInvoiceRepoForPayment(this.invoice);

  @override
  Future<InvoiceModel> getInvoiceById(int id) async => invoice;

  @override
  Future<InvoiceModel> recordPayment({
    required int invoiceId,
    required double amount,
    required PaymentMethod method,
    String? transactionId,
    String? note,
  }) async {
    final newPaid = invoice.totalPaid + amount;
    final newBalance = (invoice.grandTotal - newPaid).clamp(0.0, double.infinity);
    final newStatus = newBalance <= 0.01 ? InvoiceStatus.paid : InvoiceStatus.partiallyPaid;

    final newPayment = PaymentModel(
      id: 99,
      invoiceId: invoiceId,
      amount: amount,
      method: method,
      paymentDate: DateTime.now(),
      transactionId: transactionId,
      note: note,
    );

    invoice = invoice.copyWith(
      totalPaid: newPaid,
      balanceDue: newBalance,
      status: newStatus,
      payments: [...invoice.payments, newPayment],
    );

    return invoice;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecordPaymentBottomSheet & Settlement Tests', () {
    testWidgets('Renders bottom sheet with balance due auto-filled and records payment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final initialInvoice = InvoiceModel(
        id: 101,
        businessId: 1,
        invoiceNumber: 'INV-101',
        invoiceDate: DateTime(2026, 9, 1),
        customer: const CustomerModel(
          id: 1,
          businessId: 1,
          name: 'Priya Sharma',
          phone: '+91 98765 00000',
        ),
        items: const [
          InvoiceItemModel(
            description: 'Consulting',
            quantity: 1,
            rate: 10000.0,
            taxableAmount: 10000.0,
            totalAmount: 11800.0,
          ),
        ],
        subtotal: 10000.0,
        taxableAmount: 10000.0,
        grandTotal: 11800.0,
        totalPaid: 0.0,
        balanceDue: 11800.0,
        status: InvoiceStatus.unpaid,
      );

      final fakeRepo = _FakeInvoiceRepoForPayment(initialInvoice);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RecordPaymentBottomSheet(invoice: initialInvoice),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Payment Amount (₹)'), findsOneWidget);
      expect(find.text('11800'), findsOneWidget);
      expect(find.text('Confirm Payment'), findsOneWidget);

      // Tap Confirm Payment
      await tester.tap(find.text('Confirm Payment'));
      await tester.pumpAndSettle();

      // Verify that payment was recorded and invoice status updated to paid
      expect(fakeRepo.invoice.totalPaid, 11800.0);
      expect(fakeRepo.invoice.balanceDue, 0.0);
      expect(fakeRepo.invoice.status, InvoiceStatus.paid);
      expect(fakeRepo.invoice.payments.length, 1);
    });
  });
}
