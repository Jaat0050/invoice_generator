import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_generator/features/templates/presentation/screens/template_selector_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TemplateConfigNotifier Tests', () {
    test('Defaults and state updates work as expected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(templateConfigProvider);
      expect(initial.templateId, 'classic');
      expect(initial.primaryColorHex, 0xFF4F46E5);
      expect(initial.showLogo, true);
      expect(initial.showSignature, true);

      // Change template
      container.read(templateConfigProvider.notifier).setTemplateId('modern');
      expect(container.read(templateConfigProvider).templateId, 'modern');

      // Change primary color
      container.read(templateConfigProvider.notifier).setPrimaryColor(0xFF059669);
      expect(container.read(templateConfigProvider).primaryColorHex, 0xFF059669);

      // Toggle options
      container.read(templateConfigProvider.notifier).toggleOption(showLogo: false, showUpiQr: false);
      expect(container.read(templateConfigProvider).showLogo, false);
      expect(container.read(templateConfigProvider).showUpiQr, false);
      expect(container.read(templateConfigProvider).showSignature, true);
    });
  });

  group('TemplateSelectorScreen Widget Tests', () {
    testWidgets('Renders responsive layout on mobile screen (<768px) with tabs', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TemplateSelectorScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Invoice Templates & Design'), findsOneWidget);
      expect(find.text('Customize'), findsOneWidget);
      expect(find.text('Live Preview'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('1. Select Layout Style'.toUpperCase()), findsOneWidget);
      expect(find.text('Classic Corporate'), findsOneWidget);
      expect(find.text('Modern Slate'), findsOneWidget);
    });

    testWidgets('Renders split side-by-side view on tablet/desktop screen (>=768px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TemplateSelectorScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Invoice Templates & Design'), findsOneWidget);
      // No TabBar on tablet/desktop
      expect(find.byType(TabBar), findsNothing);
      expect(find.text('1. Select Layout Style'.toUpperCase()), findsOneWidget);
      expect(find.text('2. Brand Accent Color'.toUpperCase()), findsOneWidget);
    });
  });
}
