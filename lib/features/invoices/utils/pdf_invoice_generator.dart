import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:invoice_generator/core/utils/currency_formatter.dart';
import 'package:invoice_generator/core/utils/date_formatter.dart';
import 'package:invoice_generator/core/utils/number_to_words.dart';
import 'package:invoice_generator/features/auth/data/models/business_model.dart';
import 'package:invoice_generator/features/invoices/data/models/invoice_model.dart';
import 'package:invoice_generator/features/templates/data/models/template_config_model.dart';

class PdfInvoiceGenerator {
  PdfInvoiceGenerator._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  static Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;

    final cleanUrl = url.trim();

    try {
      // 1. Data URI (Base64)
      if (cleanUrl.startsWith('data:image')) {
        final commaIdx = cleanUrl.indexOf(',');
        final base64Data = commaIdx != -1 ? cleanUrl.substring(commaIdx + 1) : cleanUrl;
        return base64Decode(base64Data);
      }

      // 2. Local File path
      if (!kIsWeb && (cleanUrl.startsWith('/') || cleanUrl.startsWith('file://'))) {
        final filePath = cleanUrl.replaceFirst('file://', '');
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }

      // 3. Raw Base64 string without data:image prefix
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        try {
          return base64Decode(cleanUrl);
        } catch (_) {}
      }

      // 4. Remote HTTP / HTTPS URL
      final response = await _dio.get<List<int>>(
        cleanUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      debugPrint('PdfInvoiceGenerator failed to load image from "$url": $e');
    }
    return null;
  }

  static Future<Uint8List> generatePdf({
    required InvoiceModel invoice,
    required BusinessModel business,
    TemplateConfigModel config = const TemplateConfigModel(),
  }) async {
    final pdf = pw.Document();

    pw.Font regularFont;
    pw.Font boldFont;

    try {
      regularFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    // Load logo and signature images if configured
    Uint8List? logoBytes;
    if (config.showLogo && business.logoUrl != null && business.logoUrl!.isNotEmpty) {
      logoBytes = await _fetchImageBytes(business.logoUrl);
    }

    Uint8List? signatureBytes;
    if (config.showSignature && business.signatureUrl != null && business.signatureUrl!.isNotEmpty) {
      signatureBytes = await _fetchImageBytes(business.signatureUrl);
    }

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    final primaryPdfColor = PdfColor.fromInt(config.primaryColorHex);
    final darkNeutral = PdfColor.fromHex('#0F172A');
    final secondaryText = PdfColor.fromHex('#475569');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final borderSubtle = PdfColor.fromHex('#E2E8F0');
    final alertBg = PdfColor.fromHex('#FEF2F2');
    final alertText = PdfColor.fromHex('#B91C1C');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header Section
            _buildHeader(business, invoice, primaryPdfColor, darkNeutral, secondaryText, config, logoBytes: logoBytes),
            pw.SizedBox(height: 20),

            // 2. Customer "Billed To" & Invoice Meta Details
            _buildBillToAndMeta(business, invoice, primaryPdfColor, darkNeutral, secondaryText, borderSubtle, config),
            pw.SizedBox(height: 18),

            // 3. Line Items Table
            _buildItemsTable(invoice, primaryPdfColor, darkNeutral, borderSubtle, lightBg, config),
            pw.SizedBox(height: 14),

            // 4. Totals, Tax Breakdown & Words
            _buildTotalsAndTaxSummary(invoice, primaryPdfColor, darkNeutral, secondaryText, borderSubtle, lightBg),
            pw.SizedBox(height: 16),

            // 5. Payment Due Highlight & Status
            if (config.showPaymentDueAlert && invoice.balanceDue > 0) ...[
              _buildPaymentDueBlock(invoice, alertBg, alertText, borderSubtle),
              pw.SizedBox(height: 16),
            ],

            // 6. Bank Details, UPI QR Code & Signature
            _buildFooterPaymentAndSignature(business, invoice, primaryPdfColor, darkNeutral, secondaryText, borderSubtle, config, signatureBytes: signatureBytes),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    BusinessModel business,
    InvoiceModel invoice,
    PdfColor primaryColor,
    PdfColor darkNeutral,
    PdfColor secondaryText,
    TemplateConfigModel config, {
    Uint8List? logoBytes,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null) ...[
                pw.Container(
                  width: 48,
                  height: 48,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      business.name,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (business.legalName != null && business.legalName != business.name) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        business.legalName!,
                        style: pw.TextStyle(fontSize: 9, color: secondaryText),
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    if (business.address != null)
                      pw.Text(
                        '${business.address!}, ${business.city ?? ""}, ${business.state} - ${business.pincode ?? ""}',
                        style: pw.TextStyle(fontSize: 8.5, color: secondaryText),
                      ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Phone: ${business.phone ?? ""} | Email: ${business.email ?? ""}',
                      style: pw.TextStyle(fontSize: 8.5, color: secondaryText),
                    ),
                    if (config.showGstin && business.gstin != null && invoice.isGst) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'GSTIN: ${business.gstin!} | PAN: ${business.pan ?? "N/A"}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkNeutral),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  invoice.invoiceTitle.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.invoiceNumber,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: darkNeutral,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Date: ${DateFormatter.format(invoice.invoiceDate)}',
                style: pw.TextStyle(fontSize: 9, color: secondaryText),
              ),
              if (invoice.dueDate != null) ...[
                pw.Text(
                  'Due Date: ${DateFormatter.format(invoice.dueDate!)}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
              ],
              if (invoice.referenceNumber != null) ...[
                pw.Text(
                  'Ref/PO: ${invoice.referenceNumber}',
                  style: pw.TextStyle(fontSize: 9, color: secondaryText),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBillToAndMeta(
    BusinessModel business,
    InvoiceModel invoice,
    PdfColor primaryColor,
    PdfColor darkNeutral,
    PdfColor secondaryText,
    PdfColor borderSubtle,
    TemplateConfigModel config,
  ) {
    final pos = invoice.placeOfSupply ?? invoice.customer.billingState;
    final isPosNone = pos.trim().isEmpty ||
        pos.trim().toLowerCase() == 'none' ||
        pos.trim().toLowerCase() == 'n/a' ||
        pos.trim().toLowerCase() == 'not applicable';

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderSubtle),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Bill To
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO / BUYER:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  invoice.customer.companyName ?? invoice.customer.name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: darkNeutral,
                  ),
                ),
                if (invoice.customer.companyName != null)
                  pw.Text(
                    'Attn: ${invoice.customer.name}',
                    style: pw.TextStyle(fontSize: 9, color: secondaryText),
                  ),
                if (invoice.customer.billingAddress != null)
                  pw.Text(
                    '${invoice.customer.billingAddress!}, ${invoice.customer.billingCity ?? ""}',
                    style: pw.TextStyle(fontSize: 9, color: secondaryText),
                  ),
                pw.Text(
                  'State: ${invoice.customer.billingState} (Code: ${invoice.customer.billingStateCode ?? ""})',
                  style: pw.TextStyle(fontSize: 9, color: secondaryText),
                ),
                if (config.showCustomerGstin && invoice.customer.gstin != null && invoice.isGst) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'GSTIN: ${invoice.customer.gstin!}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNeutral),
                  ),
                ],
              ],
            ),
          ),
          if (config.showSupplyDetails) ...[
            pw.SizedBox(width: 16),
            // Supply Place & Tax Mode
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SUPPLY & DOCUMENT DETAILS:',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    isPosNone ? 'Place of Supply: Not Applicable' : 'Place of Supply: $pos',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNeutral),
                  ),
                  pw.Text(
                    invoice.isGst
                        ? (invoice.gstType == GstType.intraState
                            ? 'Tax Type: Intra-State (CGST + SGST)'
                            : 'Tax Type: Inter-State (IGST)')
                        : 'Tax Type: Non-GST Supply / Bill of Supply',
                    style: pw.TextStyle(fontSize: 9, color: secondaryText),
                  ),
                  if (invoice.isGst)
                    pw.Text(
                      'Reverse Charge: NO',
                      style: pw.TextStyle(fontSize: 9, color: secondaryText),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    InvoiceModel invoice,
    PdfColor primaryColor,
    PdfColor darkNeutral,
    PdfColor borderSubtle,
    PdfColor lightBg,
    TemplateConfigModel config,
  ) {
    final isGst = invoice.isGst;

    final headers = [
      '#',
      'Item Description',
      if (config.showHsnSac) 'HSN/SAC',
      'Qty',
      'Rate (Rs.)',
      'Disc',
      if (isGst) 'Taxable (Rs.)',
      if (isGst) (invoice.gstType == GstType.intraState ? 'CGST / SGST' : 'IGST'),
      'Total (Rs.)',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderSubtle, width: 0.5),
      columnWidths: isGst
          ? {
              0: const pw.FixedColumnWidth(20),
              1: const pw.FlexColumnWidth(3.5),
              if (config.showHsnSac) 2: const pw.FixedColumnWidth(48),
              3: const pw.FixedColumnWidth(28),
              4: const pw.FixedColumnWidth(54),
              5: const pw.FixedColumnWidth(36),
              6: const pw.FixedColumnWidth(56),
              7: const pw.FixedColumnWidth(60),
              8: const pw.FixedColumnWidth(62),
            }
          : {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(4.0),
              if (config.showHsnSac) 2: const pw.FixedColumnWidth(55),
              3: const pw.FixedColumnWidth(35),
              4: const pw.FixedColumnWidth(65),
              5: const pw.FixedColumnWidth(45),
              6: const pw.FixedColumnWidth(75),
            },
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBg),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: darkNeutral,
                ),
                textAlign: header == '#' || header == 'Item Description' ? pw.TextAlign.left : pw.TextAlign.right,
              ),
            );
          }).toList(),
        ),

        // Item Rows
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;

          String taxStr = '';
          if (isGst) {
            if (invoice.gstType == GstType.intraState) {
              final rateHalf = (item.taxRate / 2).toStringAsFixed(1).replaceAll('.0', '');
              taxStr = '$rateHalf% + $rateHalf%';
            } else {
              taxStr = '${item.taxRate.toInt()}%';
            }
          }

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('$index', style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item.description, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              if (config.showHsnSac)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item.hsnSac ?? '-', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('${item.quantity.toInt()} ${item.unit}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(CurrencyFormatter.format(item.rate, showSymbol: false), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  item.discountAmount > 0 ? CurrencyFormatter.format(item.discountAmount, showSymbol: false) : '-',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              if (isGst)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(CurrencyFormatter.format(item.taxableAmount, showSymbol: false), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                ),
              if (isGst)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(taxStr, style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.right),
                ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(CurrencyFormatter.format(item.totalAmount, showSymbol: false), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTotalsAndTaxSummary(
    InvoiceModel invoice,
    PdfColor primaryColor,
    PdfColor darkNeutral,
    PdfColor secondaryText,
    PdfColor borderSubtle,
    PdfColor lightBg,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left: Amount in Words
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightBg,
              border: pw.Border.all(color: borderSubtle),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AMOUNT IN WORDS:',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  NumberToWords.convertToIndianRupees(invoice.grandTotal),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNeutral),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Terms & Conditions:\n1. Payment is strictly due by the due date specified.\n2. Invoices not paid on time are subject to a 1.5% monthly late fee.\n3. Goods once sold will not be taken back.',
                  style: pw.TextStyle(fontSize: 7.5, color: secondaryText),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        // Right: Financial Breakdown
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            children: [
              if (invoice.isGst) ...[
                _buildSummaryPdfRow('Taxable Amount', 'Rs. ${CurrencyFormatter.format(invoice.taxableAmount, showSymbol: false)}', darkNeutral),
                if (invoice.totalDiscount > 0)
                  _buildSummaryPdfRow('Total Discount', '-Rs. ${CurrencyFormatter.format(invoice.totalDiscount, showSymbol: false)}', secondaryText),
                if (invoice.gstType == GstType.intraState) ...[
                  _buildSummaryPdfRow('CGST', 'Rs. ${CurrencyFormatter.format(invoice.totalCgst, showSymbol: false)}', secondaryText),
                  _buildSummaryPdfRow('SGST', 'Rs. ${CurrencyFormatter.format(invoice.totalSgst, showSymbol: false)}', secondaryText),
                ] else ...[
                  _buildSummaryPdfRow('IGST', 'Rs. ${CurrencyFormatter.format(invoice.totalIgst, showSymbol: false)}', secondaryText),
                ],
              ] else ...[
                _buildSummaryPdfRow('Subtotal', 'Rs. ${CurrencyFormatter.format(invoice.subtotal, showSymbol: false)}', darkNeutral),
                if (invoice.totalDiscount > 0)
                  _buildSummaryPdfRow('Total Discount', '-Rs. ${CurrencyFormatter.format(invoice.totalDiscount, showSymbol: false)}', secondaryText),
              ],
              if (invoice.roundOff != 0)
                _buildSummaryPdfRow('Round Off', 'Rs. ${CurrencyFormatter.format(invoice.roundOff, showSymbol: false)}', secondaryText),
              pw.Divider(color: borderSubtle, thickness: 1),
              _buildSummaryPdfRow(
                'Grand Total',
                'Rs. ${CurrencyFormatter.format(invoice.grandTotal, showSymbol: false)}',
                primaryColor,
                isBold: true,
                fontSize: 12,
              ),
              _buildSummaryPdfRow('Amount Paid', 'Rs. ${CurrencyFormatter.format(invoice.totalPaid, showSymbol: false)}', secondaryText),
              _buildSummaryPdfRow('Balance Due', 'Rs. ${CurrencyFormatter.format(invoice.balanceDue, showSymbol: false)}', darkNeutral, isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryPdfRow(
    String label,
    String value,
    PdfColor color, {
    bool isBold = false,
    double fontSize = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentDueBlock(
    InvoiceModel invoice,
    PdfColor alertBg,
    PdfColor alertText,
    PdfColor borderSubtle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: alertBg,
        border: pw.Border.all(color: PdfColor.fromHex('#FECACA')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'PAYMENT DUE: Rs. ${CurrencyFormatter.format(invoice.balanceDue, showSymbol: false)}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: alertText),
          ),
          pw.Text(
            invoice.dueDate != null
                ? 'Please pay on or before ${DateFormatter.format(invoice.dueDate!)}'
                : 'Payment balance due upon receipt',
            style: pw.TextStyle(fontSize: 8.5, color: alertText),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterPaymentAndSignature(
    BusinessModel business,
    InvoiceModel invoice,
    PdfColor primaryColor,
    PdfColor darkNeutral,
    PdfColor secondaryText,
    PdfColor borderSubtle,
    TemplateConfigModel config, {
    Uint8List? signatureBytes,
  }) {
    final upiUrl = 'upi://pay?pa=${business.upiId ?? ""}&pn=${Uri.encodeComponent(business.name)}&am=${invoice.balanceDue.toStringAsFixed(2)}&cu=INR';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Bank Details & UPI QR
        if (config.showBankDetails || (config.showUpiQr && business.upiId != null)) ...[
          pw.Expanded(
            flex: 6,
            child: pw.Row(
              children: [
                if (config.showUpiQr && business.upiId != null) ...[
                  pw.Container(
                    width: 60,
                    height: 60,
                    padding: const pw.EdgeInsets.all(3),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: borderSubtle)),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: upiUrl,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                ],
                if (config.showBankDetails)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BANK & UPI TRANSFER:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.Text('Bank: ${business.bankName ?? "N/A"}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('A/C No: ${business.bankAccountNumber ?? "N/A"}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('IFSC: ${business.bankIfsc ?? "N/A"} | Branch: ${business.bankBranch ?? "N/A"}', style: const pw.TextStyle(fontSize: 8)),
                      if (business.upiId != null)
                        pw.Text('UPI ID: ${business.upiId!}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    ],
                  ),
              ],
            ),
          ),
        ],

        // Authorized Signature
        if (config.showSignature) ...[
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('For ${business.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                if (signatureBytes != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    height: 38,
                    width: 110,
                    alignment: pw.Alignment.bottomRight,
                    child: pw.Image(
                      pw.MemoryImage(signatureBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                ] else ...[
                  pw.SizedBox(height: 32),
                ],
                pw.Container(width: 120, height: 1, color: darkNeutral),
                pw.SizedBox(height: 2),
                pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 8, color: secondaryText)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
