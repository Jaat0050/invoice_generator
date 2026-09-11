import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_generator/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:invoice_generator/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:invoice_generator/features/invoices/presentation/screens/invoice_list_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/gst_calculator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../items/data/models/item_model.dart';
import '../../../items/data/repositories/item_repository.dart';
import '../../data/models/invoice_item_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';

class CreateInvoiceWizardScreen extends ConsumerStatefulWidget {
  const CreateInvoiceWizardScreen({super.key});

  @override
  ConsumerState<CreateInvoiceWizardScreen> createState() => _CreateInvoiceWizardScreenState();
}

class _CreateInvoiceWizardScreenState extends ConsumerState<CreateInvoiceWizardScreen> {
  int _currentStep = 0;

  // Step 1: Info
  final _invoiceNumberController = TextEditingController(text: 'INV-1004');
  final _referenceNumberController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));

  // Step 2: Customer
  CustomerModel? _selectedCustomer;

  // Step 3: Items
  final List<InvoiceItemModel> _lineItems = [];

  // Step 4: Tax & Discount
  double _invoiceDiscount = 0.0;
  bool _enableRoundOff = true;
  GstSupplyType _supplyType = GstSupplyType.intraState;

  @override
  void initState() {
    super.initState();
    _lineItems.add(
      const InvoiceItemModel(
        description: 'MacBook Pro 16" M3 Max',
        hsnSac: '84713010',
        quantity: 1,
        unit: 'NOS',
        rate: 249900.0,
        taxableAmount: 249900.0,
        taxRate: 18.0,
        cgstAmount: 22491.0,
        sgstAmount: 22491.0,
        totalAmount: 294882.0,
      ),
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  void _recalculateSupplyType() {
    if (_selectedCustomer != null) {
      _supplyType = GstCalculator.determineSupplyType(
        businessState: 'Maharashtra',
        customerBillingState: _selectedCustomer!.billingState,
      );
    }
  }

  InvoiceTotalsCalculation _calculateTotals() {
    final calcs = _lineItems.map((item) {
      return GstCalculator.calculateLineItem(
        quantity: item.quantity,
        rate: item.rate,
        discountPercent: item.discountPercent,
        discountFixed: item.discountAmount,
        taxRate: item.taxRate,
        supplyType: _supplyType,
      );
    }).toList();

    return GstCalculator.calculateInvoiceTotals(
      items: calcs,
      invoiceDiscount: _invoiceDiscount,
      enableRoundOff: _enableRoundOff,
    );
  }

  Future<void> _submitInvoice() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      setState(() => _currentStep = 1);
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      setState(() => _currentStep = 2);
      return;
    }

    final totals = _calculateTotals();

    final newInvoice = InvoiceModel(
      id: 0,
      businessId: 1,
      invoiceNumber: _invoiceNumberController.text.trim(),
      referenceNumber: _referenceNumberController.text.trim().isEmpty ? null : _referenceNumberController.text.trim(),
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      customer: _selectedCustomer!,
      items: _lineItems,
      gstType: _supplyType == GstSupplyType.intraState ? GstType.intraState : GstType.interState,
      subtotal: totals.subtotal,
      totalDiscount: totals.totalDiscount,
      taxableAmount: totals.taxableAmount,
      totalCgst: totals.totalCgst,
      totalSgst: totals.totalSgst,
      totalIgst: totals.totalIgst,
      roundOff: totals.roundOff,
      grandTotal: totals.grandTotal,
      balanceDue: totals.grandTotal,
      status: InvoiceStatus.unpaid,
      createdAt: DateTime.now(),
    );

    final repo = ref.read(invoiceRepositoryProvider);
    final saved = await repo.createInvoice(newInvoice);

    if (mounted) {
      ref.invalidate(invoiceListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${saved.invoiceNumber} created!')),
      );
      context.go('/invoices/${saved.id}/preview');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create GST Invoice'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        type: StepperType.horizontal,
        elevation: 0,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _submitInvoice();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            context.pop();
          }
        },
        steps: [
          Step(
            title: const Text('Info'),
            isActive: _currentStep >= 0,
            content: _buildStep1Info(),
          ),
          Step(
            title: const Text('Client'),
            isActive: _currentStep >= 1,
            content: _buildStep2Customer(),
          ),
          Step(
            title: const Text('Items'),
            isActive: _currentStep >= 2,
            content: _buildStep3Items(),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 3,
            content: _buildStep4Totals(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Invoice Number',
          controller: _invoiceNumberController,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Reference / Purchase Order (PO) #',
          hint: 'e.g. PO-89421',
          controller: _referenceNumberController,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Invoice Date', style: AppTypography.labelMedium),
          subtitle: Text(DateFormatter.format(_invoiceDate), style: AppTypography.bodyMedium),
          trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _invoiceDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _invoiceDate = picked);
          },
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Payment Due Date', style: AppTypography.labelMedium),
          subtitle: Text(DateFormatter.format(_dueDate), style: AppTypography.bodyMedium),
          trailing: const Icon(Icons.event_available_rounded, color: AppColors.primary),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _dueDate = picked);
          },
        ),
        const SizedBox(height: 12),
        // Payment Terms Quick Select
        Text('Quick Payment Terms', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Immediate'),
              onPressed: () => setState(() => _dueDate = _invoiceDate),
            ),
            ActionChip(
              label: const Text('Net 15 Days'),
              onPressed: () => setState(() => _dueDate = _invoiceDate.add(const Duration(days: 15))),
            ),
            ActionChip(
              label: const Text('Net 30 Days'),
              onPressed: () => setState(() => _dueDate = _invoiceDate.add(const Duration(days: 30))),
            ),
            ActionChip(
              label: const Text('Net 60 Days'),
              onPressed: () => setState(() => _dueDate = _invoiceDate.add(const Duration(days: 60))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Customer() {
    final customersAsync = ref.watch(customerListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Customer', style: AppTypography.headingSmall),
            TextButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Quick Add'),
              onPressed: () async {
                final added = await CustomerFormBottomSheet.show(context);
                if (added != null) {
                  setState(() {
                    _selectedCustomer = added;
                    _recalculateSupplyType();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        customersAsync.when(
          data: (customers) {
            return Column(
              children: customers.map((c) {
                final isSelected = _selectedCustomer?.id == c.id;
                return Card(
                  color: isSelected ? AppColors.primaryContainer : AppColors.surface,
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedCustomer = c;
                        _recalculateSupplyType();
                      });
                    },
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                      child: Icon(
                        Icons.person_rounded,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      c.companyName ?? c.name,
                      style: AppTypography.labelLarge,
                    ),
                    subtitle: Text('${c.name} • ${c.billingCity ?? ""}, ${c.billingState} (Code ${c.billingStateCode})'),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildStep3Items() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Items (${_lineItems.length})', style: AppTypography.headingSmall),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Catalog'),
                  onPressed: () => _showAddCatalogItemModal(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Custom'),
                  onPressed: () => _showCustomItemModal(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._lineItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.description, style: AppTypography.labelLarge),
                      ),
                      Text(
                        CurrencyFormatter.format(item.totalAmount),
                        style: AppTypography.currencyMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () => setState(() => _lineItems.removeAt(idx)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HSN: ${item.hsnSac ?? "N/A"}  |  GST: ${item.taxRate.toInt()}%',
                        style: AppTypography.bodySmall,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                            onPressed: () {
                              if (item.quantity > 1) {
                                final newQty = item.quantity - 1;
                                final calc = GstCalculator.calculateLineItem(
                                  quantity: newQty,
                                  rate: item.rate,
                                  taxRate: item.taxRate,
                                  supplyType: _supplyType,
                                );
                                setState(() {
                                  _lineItems[idx] = item.copyWith(
                                    quantity: newQty,
                                    taxableAmount: calc.taxableAmount,
                                    cgstAmount: calc.cgstAmount,
                                    sgstAmount: calc.sgstAmount,
                                    igstAmount: calc.igstAmount,
                                    totalAmount: calc.totalAmount,
                                  );
                                });
                              }
                            },
                          ),
                          Text('${item.quantity.toInt()} ${item.unit}', style: AppTypography.labelLarge),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            onPressed: () {
                              final newQty = item.quantity + 1;
                              final calc = GstCalculator.calculateLineItem(
                                quantity: newQty,
                                rate: item.rate,
                                taxRate: item.taxRate,
                                supplyType: _supplyType,
                              );
                              setState(() {
                                _lineItems[idx] = item.copyWith(
                                  quantity: newQty,
                                  taxableAmount: calc.taxableAmount,
                                  cgstAmount: calc.cgstAmount,
                                  sgstAmount: calc.sgstAmount,
                                  igstAmount: calc.igstAmount,
                                  totalAmount: calc.totalAmount,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showCustomItemModal() {
    final nameCtrl = TextEditingController();
    final hsnCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    double taxRate = 18.0;
    String unit = 'PCS';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add Line Item', style: AppTypography.headingMedium),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Description', hint: 'e.g. Website Hosting Fee', controller: nameCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: AppTextField(label: 'HSN/SAC', hint: '998314', controller: hsnCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: AppTextField(label: 'Qty', keyboardType: TextInputType.number, controller: qtyCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: AppTextField(label: 'Rate (₹)', keyboardType: TextInputType.number, controller: rateCtrl)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          value: taxRate,
                          decoration: const InputDecoration(labelText: 'GST Tax Slab'),
                          items: const [
                            DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                            DropdownMenuItem(value: 5.0, child: Text('5%')),
                            DropdownMenuItem(value: 12.0, child: Text('12%')),
                            DropdownMenuItem(value: 18.0, child: Text('18% (Standard)')),
                            DropdownMenuItem(value: 28.0, child: Text('28%')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => taxRate = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const [
                            DropdownMenuItem(value: 'PCS', child: Text('PCS')),
                            DropdownMenuItem(value: 'NOS', child: Text('NOS')),
                            DropdownMenuItem(value: 'HRS', child: Text('HRS')),
                            DropdownMenuItem(value: 'BOX', child: Text('BOX')),
                            DropdownMenuItem(value: 'KGS', child: Text('KGS')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => unit = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Add to Invoice',
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final rate = double.tryParse(rateCtrl.text) ?? 0.0;
                      final qty = double.tryParse(qtyCtrl.text) ?? 1.0;

                      final calc = GstCalculator.calculateLineItem(
                        quantity: qty,
                        rate: rate,
                        taxRate: taxRate,
                        supplyType: _supplyType,
                      );

                      setState(() {
                        _lineItems.add(
                          InvoiceItemModel(
                            description: nameCtrl.text.trim(),
                            hsnSac: hsnCtrl.text.trim().isEmpty ? null : hsnCtrl.text.trim(),
                            quantity: qty,
                            unit: unit,
                            rate: rate,
                            taxableAmount: calc.taxableAmount,
                            taxRate: taxRate,
                            cgstAmount: calc.cgstAmount,
                            sgstAmount: calc.sgstAmount,
                            igstAmount: calc.igstAmount,
                            totalAmount: calc.totalAmount,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCatalogItemModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final repo = ref.read(itemRepositoryProvider);
        return FutureBuilder<List<ItemModel>>(
          future: repo.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final items = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Pick Item from Catalog', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                ...items.map((item) {
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('HSN: ${item.hsnSac ?? "N/A"} • GST: ${item.taxRate.toInt()}%'),
                    trailing: Text(CurrencyFormatter.format(item.rate)),
                    onTap: () {
                      final calc = GstCalculator.calculateLineItem(
                        quantity: 1,
                        rate: item.rate,
                        taxRate: item.taxRate,
                        supplyType: _supplyType,
                      );
                      setState(() {
                        _lineItems.add(
                          InvoiceItemModel(
                            itemId: item.id,
                            description: item.name,
                            hsnSac: item.hsnSac,
                            quantity: 1,
                            unit: item.unit,
                            rate: item.rate,
                            taxableAmount: calc.taxableAmount,
                            taxRate: item.taxRate,
                            cgstAmount: calc.cgstAmount,
                            sgstAmount: calc.sgstAmount,
                            igstAmount: calc.igstAmount,
                            totalAmount: calc.totalAmount,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStep4Totals() {
    final totals = _calculateTotals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Supply Type Selector Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.roundedMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GST Tax Regime', style: AppTypography.labelMedium),
                  Text(
                    _supplyType == GstSupplyType.intraState
                        ? 'Intra-State (CGST + SGST)'
                        : 'Inter-State (IGST)',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Switch(
                value: _supplyType == GstSupplyType.interState,
                onChanged: (val) {
                  setState(() {
                    _supplyType = val ? GstSupplyType.interState : GstSupplyType.intraState;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Extra Discount Input & Round-off Switch
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Invoice Discount (₹)',
                  prefixText: '₹ ',
                ),
                onChanged: (val) {
                  setState(() {
                    _invoiceDiscount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Auto Round-off', style: TextStyle(fontSize: 13)),
                value: _enableRoundOff,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _enableRoundOff = val ?? true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary Breakdown Table
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal (Gross)', totals.subtotal),
                if (totals.totalDiscount > 0)
                  _buildSummaryRow('Total Discount', -totals.totalDiscount, color: AppColors.successDark),
                _buildSummaryRow('Taxable Value', totals.taxableAmount),
                const Divider(height: 20),
                if (_supplyType == GstSupplyType.intraState) ...[
                  _buildSummaryRow('CGST', totals.totalCgst),
                  _buildSummaryRow('SGST', totals.totalSgst),
                ] else ...[
                  _buildSummaryRow('IGST', totals.totalIgst),
                ],
                if (totals.roundOff != 0)
                  _buildSummaryRow('Round Off', totals.roundOff),
                const Divider(height: 20),
                _buildSummaryRow(
                  'Grand Total',
                  totals.grandTotal,
                  isBold: true,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Generate & Preview Invoice PDF',
          icon: Icons.picture_as_pdf_outlined,
          onPressed: _submitInvoice,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              fontSize: fontSize,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTypography.currencyMedium.copyWith(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
