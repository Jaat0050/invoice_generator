import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/payment_model.dart';

class PaymentReceiptDialog extends StatelessWidget {
  final PaymentModel payment;
  final String invoiceNumber;
  final String customerName;

  const PaymentReceiptDialog({
    super.key,
    required this.payment,
    required this.invoiceNumber,
    required this.customerName,
  });

  static Future<void> show(
    BuildContext context, {
    required PaymentModel payment,
    required String invoiceNumber,
    required String customerName,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PaymentReceiptDialog(
        payment: payment,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Icon
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.successDark, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Receipt',
              style: AppTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Receipt #${payment.id}',
              style: AppTypography.labelSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Amount Received Highlight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppDimensions.roundedMd,
              ),
              child: Column(
                children: [
                  Text('Amount Received', style: AppTypography.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(payment.amount),
                    style: AppTypography.currencyLarge.copyWith(color: AppColors.successDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details
            _buildReceiptRow('Invoice Number', invoiceNumber),
            _buildReceiptRow('Received From', customerName),
            _buildReceiptRow('Date & Time', DateFormatter.format(payment.paymentDate)),
            _buildReceiptRow('Payment Mode', payment.method.name.toUpperCase()),
            if (payment.transactionId != null)
              _buildReceiptRow('Ref / Txn ID', payment.transactionId!),
            if (payment.note != null)
              _buildReceiptRow('Note', payment.note!),

            const SizedBox(height: 24),
            AppButton(
              label: 'Share Receipt',
              icon: Icons.share_rounded,
              onPressed: () {
                final receiptText = '''
🧾 *PAYMENT RECEIPT*
Receipt No: #${payment.id}
Invoice No: $invoiceNumber
Received From: $customerName
Amount: ${CurrencyFormatter.format(payment.amount)}
Date: ${DateFormatter.format(payment.paymentDate)}
Mode: ${payment.method.name.toUpperCase()}
${payment.transactionId != null ? 'Ref: ${payment.transactionId}' : ''}

Thank you for your payment!
''';
                SharePlus.instance.share(
                  ShareParams(text: receiptText, subject: 'Payment Receipt for $invoiceNumber'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
