import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_generator/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:invoice_generator/features/invoices/presentation/screens/create_invoice_wizard_screen.dart';
import 'package:invoice_generator/features/invoices/presentation/screens/invoice_detail_screen.dart';

void main() {
  group('Core MVP Screens Tests', () {
    testWidgets('DashboardScreen renders KPIs, Quick Actions, and Recent Invoices', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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
