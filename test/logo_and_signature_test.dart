import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:invoice_generator/core/services/image_compressor_service.dart';
import 'package:invoice_generator/core/widgets/image_upload_card.dart';
import 'package:invoice_generator/core/widgets/signature_pad_dialog.dart';
import 'package:invoice_generator/features/auth/data/models/business_model.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_item_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';
import 'package:invoice_generator/features/invoices/utils/pdf_invoice_generator.dart';
import 'package:invoice_generator/features/templates/data/models/template_config_model.dart';

import 'dart:math' as math;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompressorService Tests', () {
    test('Compresses large image to strictly <= 200KB (maxTargetSizeBytes)', () {
      final random = math.Random(42);
      // Create a 1800x1800 synthetic image with pseudorandom noise
      final rawImage = img.Image(width: 1800, height: 1800);
      for (int y = 0; y < 1800; y++) {
        for (int x = 0; x < 1800; x++) {
          rawImage.setPixelRgb(x, y, random.nextInt(256), random.nextInt(256), random.nextInt(256));
        }
      }
      final rawPngBytes = Uint8List.fromList(img.encodePng(rawImage));
      expect(rawPngBytes.lengthInBytes, greaterThan(200 * 1024));

      // Test JPEG compression (Logos)
      final compressedJpg = ImageCompressorService.compressImage(
        rawPngBytes,
        preserveTransparency: false,
        maxDimension: 1024,
      );

      expect(compressedJpg.sizeInBytes, lessThanOrEqualTo(200 * 1024));
      expect(compressedJpg.mimeType, 'image/jpeg');
      expect(compressedJpg.formatExtension, 'jpg');

      // Test PNG compression with transparency (Signatures)
      final compressedPng = ImageCompressorService.compressImage(
        rawPngBytes,
        preserveTransparency: true,
        maxDimension: 800,
      );

      expect(compressedPng.sizeInBytes, lessThanOrEqualTo(200 * 1024));
      expect(compressedPng.mimeType, 'image/png');
      expect(compressedPng.formatExtension, 'png');
    });
  });

  group('Signature & Logo Widgets Tests', () {
    testWidgets('SignaturePadDialog renders pen tools, baseline, and actions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SignaturePadDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Authorized Signature'), findsOneWidget);
      expect(find.text('Save & Apply Signature'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('ImageUploadCard renders with empty state and signature mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImageUploadCard(
                title: 'Authorized Signature *',
                subtitle: 'Mandatory signature for all invoices',
                currentUrl: null,
                isSignature: true,
                onImageUpdated: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Authorized Signature *'), findsOneWidget);
      expect(find.text('+ Draw / Upload Signature *'), findsOneWidget);
      expect(find.text('Auto compressed to ≤ 200KB'), findsOneWidget);
    });
  });

  group('PDF Invoice with Logo and Signature Tests', () {
    test('Generates PDF with embedded logo and signature data URIs', () async {
      // Create small 32x32 sample images
      final logoImg = img.Image(width: 32, height: 32);
      final sigImg = img.Image(width: 32, height: 32);
      final logoBytes = img.encodeJpg(logoImg);
      final sigBytes = img.encodePng(sigImg);

      final business = BusinessModel(
        id: 1,
        name: 'Apex Solutions Pvt Ltd',
        phone: '+91 98765 43210',
        email: 'billing@apex.com',
        logoUrl: 'data:image/jpeg;base64,${base64Encode(logoBytes)}',
        signatureUrl: 'data:image/png;base64,${base64Encode(sigBytes)}',
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
          phone: '+91 98220 12345',
          billingState: 'Maharashtra',
        ),
        items: const [
          InvoiceItemModel(
            description: 'Web Development Services',
            quantity: 1,
            rate: 50000.0,
            taxableAmount: 50000.0,
            taxRate: 18.0,
            totalAmount: 59000.0,
          ),
        ],
        subtotal: 50000.0,
        taxableAmount: 50000.0,
        grandTotal: 59000.0,
        balanceDue: 59000.0,
      );

      final pdfBytes = await PdfInvoiceGenerator.generatePdf(
        invoice: invoice,
        business: business,
        config: const TemplateConfigModel(showLogo: true, showSignature: true),
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, true);
    });
  });
}
