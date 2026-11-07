import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoice_generator/features/settings/presentation/screens/business_profile_screen.dart';
import 'package:invoice_generator/features/settings/presentation/screens/bank_upi_settings_screen.dart';
import 'package:invoice_generator/features/settings/presentation/screens/app_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Settings & Profile Features Tests', () {
    testWidgets('BusinessProfileScreen renders and displays initial values', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BusinessProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Business Profile'), findsOneWidget);
      expect(find.text('Trade / Brand Name *'), findsOneWidget);
      expect(find.text('My Business'), findsWidgets);
      expect(find.text('Save Business Profile'), findsOneWidget);
    });

    testWidgets('BankUpiSettingsScreen renders and displays UPI fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BankUpiSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bank & UPI Accounts'), findsOneWidget);
      expect(find.text('UPI Virtual Payment Address (VPA) *'), findsOneWidget);
      expect(find.text('Bank Name'), findsOneWidget);
      expect(find.text('Save Bank & UPI Settings'), findsOneWidget);
    });

    testWidgets('AppSettingsScreen renders preferences toggles and terms', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('App Preferences & Defaults'), findsOneWidget);
      expect(find.text('Auto Round-Off Total'), findsOneWidget);
      expect(find.text('Indian Numbering System'), findsOneWidget);
      expect(find.text('Save Preferences'), findsOneWidget);
    });
  });
}
