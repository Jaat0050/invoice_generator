import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../../invoices/presentation/screens/invoice_detail_screen.dart';
import '../../../invoices/presentation/screens/invoice_list_screen.dart';
import '../../data/models/payment_model.dart';
import 'payment_receipt_dialog.dart';

class RecordPaymentBottomSheet extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const RecordPaymentBottomSheet({super.key, required this.invoice});

  static Future<void> show(BuildContext context, InvoiceModel invoice) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentBottomSheet(invoice: invoice),
    );
  }

  @override
  ConsumerState<RecordPaymentBottomSheet> createState() => _RecordPaymentBottomSheetState();
}

class _RecordPaymentBottomSheetState extends ConsumerState<RecordPaymentBottomSheet> {
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.balanceDue > 0
          ? widget.invoice.balanceDue.toStringAsFixed(0)
          : widget.invoice.grandTotal.toStringAsFixed(0),
    );
    _referenceController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final updatedInvoice = await repo.recordPayment(
        invoiceId: widget.invoice.id,
        amount: amount,
        method: _selectedMethod,
        transactionId: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
        note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Invalidate providers
      ref.invalidate(invoiceDetailProvider(widget.invoice.id));
      ref.invalidate(invoiceListProvider);
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        Navigator.pop(context); // close bottom sheet

        // Show receipt dialog
        PaymentReceiptDialog.show(
          context,
          payment: updatedInvoice.payments.last,
          invoiceNumber: widget.invoice.invoiceNumber,
          customerName: widget.invoice.customer.name,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceDue = widget.invoice.balanceDue;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Record Payment', style: AppTypography.headingMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.invoice.invoiceNumber} • ${widget.invoice.customer.name}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Due Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: balanceDue > 0 ? AppColors.warning.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12),
                borderRadius: AppDimensions.roundedMd,
                border: Border.all(
                  color: balanceDue > 0 ? AppColors.warning.withValues(alpha: 0.4) : AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Outstanding Balance',
                    style: AppTypography.labelMedium.copyWith(
                      color: balanceDue > 0 ? const Color(0xFFB45309) : AppColors.success,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(balanceDue),
                    style: AppTypography.currencyMedium.copyWith(
                      color: balanceDue > 0 ? const Color(0xFFB45309) : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            AppTextField(
              label: 'Payment Amount (₹)',
              hint: '0.00',
              controller: _amountController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
            ),
            const SizedBox(height: 8),

            // Quick Amount Presets
            if (balanceDue > 0) ...[
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text('Full Due (${CurrencyFormatter.format(balanceDue)})'),
                    onPressed: () => _applyQuickAmount(balanceDue),
                  ),
                  if (balanceDue > 1000)
                    ActionChip(
                      label: Text('50% (${CurrencyFormatter.format(balanceDue / 2)})'),
                      onPressed: () => _applyQuickAmount(balanceDue / 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Payment Method Selector
            Text('Payment Mode', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedMethod == method;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMethodIcon(method),
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(_getMethodLabel(method)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMethod = method);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Payment Date & Reference
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => _paymentDate = picked);
                    },
                    borderRadius: AppDimensions.roundedMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: AppDimensions.roundedMd,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(DateFormatter.format(_paymentDate), style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    hint: 'UTR / Ref No.',
                    controller: _referenceController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Optional Notes
            AppTextField(
              hint: 'Optional notes (e.g. Cleared via UPI)',
              controller: _notesController,
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: 'Confirm Payment',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isLoading,
              onPressed: _submitPayment,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return Icons.qr_code_2_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.cheque:
        return Icons.receipt_long_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.online:
        return Icons.payment_rounded;
    }
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank / NEFT';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.online:
        return 'Online Gateway';
    }
  }
}
