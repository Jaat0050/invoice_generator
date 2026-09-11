import 'dart:typed_data';
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
            _buildHeader(business, invoice, primaryPdfColor, darkNeutral, secondaryText, config),
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
            _buildFooterPaymentAndSignature(business, invoice, primaryPdfColor, darkNeutral, secondaryText, borderSubtle, config),
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
    TemplateConfigModel config,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                business.name,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (business.legalName != null && business.legalName != business.name) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  business.legalName!,
                  style: pw.TextStyle(fontSize: 10, color: secondaryText),
                ),
              ],
              pw.SizedBox(height: 4),
              if (business.address != null)
                pw.Text(
                  '${business.address!}, ${business.city ?? ""}, ${business.state} - ${business.pincode ?? ""}',
                  style: pw.TextStyle(fontSize: 9, color: secondaryText),
                ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Phone: ${business.phone ?? ""} | Email: ${business.email ?? ""}',
                style: pw.TextStyle(fontSize: 9, color: secondaryText),
              ),
              if (config.showGstin && business.gstin != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'GSTIN: ${business.gstin!} | PAN: ${business.pan ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNeutral),
                ),
              ],
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
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    fontSize: 14,
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
              pw.Text(
                'Due Date: ${DateFormatter.format(invoice.dueDate)}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
              ),
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
                if (config.showCustomerGstin && invoice.customer.gstin != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'GSTIN: ${invoice.customer.gstin!}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNeutral),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          // Supply Place & Tax Mode
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PLACE OF SUPPLY & TAX DETAILS:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Place of Supply: ${invoice.customer.billingState}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNeutral),
                ),
                pw.Text(
                  invoice.gstType == GstType.intraState
                      ? 'Tax Type: Intra-State (CGST + SGST)'
                      : 'Tax Type: Inter-State (IGST)',
                  style: pw.TextStyle(fontSize: 9, color: secondaryText),
                ),
                pw.Text(
                  'Reverse Charge: NO',
                  style: pw.TextStyle(fontSize: 9, color: secondaryText),
                ),
              ],
            ),
          ),
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
    final headers = [
      '#',
      'Item Description',
      if (config.showHsnSac) 'HSN/SAC',
      'Qty',
      'Rate (Rs.)',
      'Disc',
      'Taxable (Rs.)',
      if (invoice.gstType == GstType.intraState) 'CGST / SGST' else 'IGST',
      'Total (Rs.)',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderSubtle, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(3.5),
        if (config.showHsnSac) 2: const pw.FixedColumnWidth(48),
        3: const pw.FixedColumnWidth(28),
        4: const pw.FixedColumnWidth(54),
        5: const pw.FixedColumnWidth(36),
        6: const pw.FixedColumnWidth(56),
        7: const pw.FixedColumnWidth(60),
        8: const pw.FixedColumnWidth(62),
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
          if (invoice.gstType == GstType.intraState) {
            final rateHalf = (item.taxRate / 2).toStringAsFixed(1).replaceAll('.0', '');
            taxStr = '$rateHalf% + $rateHalf%';
          } else {
            taxStr = '${item.taxRate.toInt()}%';
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
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(CurrencyFormatter.format(item.taxableAmount, showSymbol: false), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
              ),
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
              _buildSummaryPdfRow('Taxable Amount', 'Rs. ${CurrencyFormatter.format(invoice.taxableAmount, showSymbol: false)}', darkNeutral),
              if (invoice.totalDiscount > 0)
                _buildSummaryPdfRow('Total Discount', '-Rs. ${CurrencyFormatter.format(invoice.totalDiscount, showSymbol: false)}', secondaryText),
              if (invoice.gstType == GstType.intraState) ...[
                _buildSummaryPdfRow('CGST', 'Rs. ${CurrencyFormatter.format(invoice.totalCgst, showSymbol: false)}', secondaryText),
                _buildSummaryPdfRow('SGST', 'Rs. ${CurrencyFormatter.format(invoice.totalSgst, showSymbol: false)}', secondaryText),
              ] else ...[
                _buildSummaryPdfRow('IGST', 'Rs. ${CurrencyFormatter.format(invoice.totalIgst, showSymbol: false)}', secondaryText),
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
            'Please pay on or before ${DateFormatter.format(invoice.dueDate)}',
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
    TemplateConfigModel config,
  ) {
    final upiUrl = 'upi://pay?pa=${business.upiId ?? ""}&pn=${Uri.encodeComponent(business.name)}&am=${invoice.balanceDue.toStringAsFixed(2)}&cu=INR';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Bank Details & UPI QR
        if (config.showBankDetails) ...[
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
                pw.SizedBox(height: 32),
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
