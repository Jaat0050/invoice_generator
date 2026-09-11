import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/main.dart';

void main() {
  testWidgets('Invoicify app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: InvoicifyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsWidgets);
  });
}
