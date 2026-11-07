import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/customers/presentation/screens/customer_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerFormBottomSheet Tests', () {
    testWidgets('Renders empty form and default state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomerFormBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add New Customer'), findsOneWidget);
      expect(find.text('Contact Person Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Save Customer'), findsOneWidget);
    });

    testWidgets('Handles pre-filled customer with state outside default list without crashing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const customCustomer = CustomerModel(
        id: 42,
        businessId: 1,
        name: 'Southern Enterprises',
        companyName: 'Southern Co',
        phone: '+91 94470 12345',
        billingState: 'Kerala',
        billingStateCode: '32',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomerFormBottomSheet(initialCustomer: customCustomer),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Customer'), findsOneWidget);
      expect(find.text('Southern Enterprises'), findsOneWidget);
      expect(find.text('Kerala (32)'), findsOneWidget);
    });

    testWidgets('Validates required fields on Save tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomerFormBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save Customer without entering anything
      await tester.tap(find.text('Save Customer'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('CustomerFormScreen renders full-screen Scaffold with AppBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Add New Customer'), findsOneWidget);
      expect(find.text('Customer Information'), findsOneWidget);
      expect(find.text('Save Customer'), findsOneWidget);
    });
  });
}
