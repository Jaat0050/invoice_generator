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
import '../../../../core/widgets/signature_pad_dialog.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../items/data/models/item_model.dart';
import '../../../items/data/repositories/item_repository.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
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
  bool _isSubmitting = false;

  // Invoice Mode & Title
  bool _isGst = true;
  late final TextEditingController _invoiceTitleController;

  // Step 1: Info
  final _invoiceNumberController = TextEditingController(text: 'INV-1001');
  final _referenceNumberController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate = DateTime.now().add(const Duration(days: 15));

  // Step 2: Customer & Place of Supply
  CustomerModel? _selectedCustomer;
  String? _placeOfSupply;
  String? _placeOfSupplyStateCode;

  final List<Map<String, String>> _placeOfSupplyOptions = const [
    {'name': 'None / Not Applicable', 'code': ''},
    {'name': 'Maharashtra', 'code': '27'},
    {'name': 'Karnataka', 'code': '29'},
    {'name': 'Delhi', 'code': '07'},
    {'name': 'Tamil Nadu', 'code': '33'},
    {'name': 'Gujarat', 'code': '24'},
    {'name': 'Telangana', 'code': '36'},
    {'name': 'Uttar Pradesh', 'code': '09'},
    {'name': 'West Bengal', 'code': '19'},
    {'name': 'Haryana', 'code': '06'},
    {'name': 'Rajasthan', 'code': '08'},
    {'name': 'Andhra Pradesh', 'code': '37'},
    {'name': 'Kerala', 'code': '32'},
    {'name': 'Madhya Pradesh', 'code': '23'},
    {'name': 'Punjab', 'code': '03'},
    {'name': 'Bihar', 'code': '10'},
    {'name': 'Odisha', 'code': '21'},
    {'name': 'Assam', 'code': '18'},
    {'name': 'Jharkhand', 'code': '20'},
    {'name': 'Chhattisgarh', 'code': '22'},
    {'name': 'Uttarakhand', 'code': '05'},
    {'name': 'Himachal Pradesh', 'code': '02'},
    {'name': 'Goa', 'code': '30'},
    {'name': 'Jammu and Kashmir', 'code': '01'},
    {'name': 'Chandigarh', 'code': '04'},
  ];

  // Step 3: Items
  final List<InvoiceItemModel> _lineItems = [];

  // Step 4: Tax & Discount
  double _invoiceDiscount = 0.0;
  bool _enableRoundOff = true;
  GstSupplyType _supplyType = GstSupplyType.intraState;

  @override
  void initState() {
    super.initState();
    _invoiceTitleController = TextEditingController(text: 'TAX INVOICE');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final business = ref.read(businessNotifierProvider).value;
      if (business != null) {
        _invoiceNumberController.text = '${business.invoicePrefix}${business.nextInvoiceNumber}';
      }
    });
  }

  @override
  void dispose() {
    _invoiceTitleController.dispose();
    _invoiceNumberController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  void _recalculateSupplyType() {
    final business = ref.read(businessNotifierProvider).value;
    final targetState = (_placeOfSupply != null &&
            _placeOfSupply != 'None' &&
            _placeOfSupply != 'None / Not Applicable')
        ? _placeOfSupply
        : _selectedCustomer?.billingState;

    _supplyType = GstCalculator.determineSupplyType(
      businessState: business?.state ?? 'Maharashtra',
      customerBillingState: targetState,
    );
  }

  void _recalculateAllItems() {
    for (int i = 0; i < _lineItems.length; i++) {
      final item = _lineItems[i];
      final calc = GstCalculator.calculateLineItem(
        quantity: item.quantity,
        rate: item.rate,
        discountPercent: item.discountPercent,
        discountFixed: item.discountAmount,
        taxRate: item.taxRate,
        supplyType: _supplyType,
        isGst: _isGst,
      );
      _lineItems[i] = item.copyWith(
        taxableAmount: calc.taxableAmount,
        cgstAmount: calc.cgstAmount,
        sgstAmount: calc.sgstAmount,
        igstAmount: calc.igstAmount,
        totalAmount: calc.totalAmount,
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
        isGst: _isGst,
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
        const SnackBar(content: Text('Please select a customer first'), backgroundColor: AppColors.error),
      );
      setState(() => _currentStep = 1);
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item'), backgroundColor: AppColors.error),
      );
      setState(() => _currentStep = 2);
      return;
    }

    // 1. Check if business has authorized signature (mandatory requirement)
    final authRepo = ref.read(authRepositoryProvider);
    var business = await authRepo.getActiveBusiness();

    if (business.signatureUrl == null || business.signatureUrl!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authorized signature is required. Please draw or upload your signature.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      if (!mounted) return;
      final signedUrl = await SignaturePadDialog.show(context);
      if (signedUrl == null || signedUrl.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice generation cancelled: Authorized signature is mandatory.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Save signature to business profile
      business = business.copyWith(signatureUrl: signedUrl);
      await ref.read(businessNotifierProvider.notifier).updateBusiness(business);
    }

    setState(() => _isSubmitting = true);

    try {
      final totals = _calculateTotals();
      final title = _invoiceTitleController.text.trim().isEmpty
          ? (_isGst ? 'TAX INVOICE' : 'BILL OF SUPPLY')
          : _invoiceTitleController.text.trim();

      final String? finalPos = (_placeOfSupply != null &&
              _placeOfSupply != 'None / Not Applicable' &&
              _placeOfSupply != 'None')
          ? _placeOfSupply
          : null;

      final newInvoice = InvoiceModel(
        id: 0,
        businessId: 1,
        invoiceNumber: _invoiceNumberController.text.trim(),
        referenceNumber: _referenceNumberController.text.trim().isEmpty ? null : _referenceNumberController.text.trim(),
        invoiceTitle: title,
        isGst: _isGst,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        customer: _selectedCustomer!,
        items: _lineItems,
        gstType: _supplyType == GstSupplyType.intraState ? GstType.intraState : GstType.interState,
        placeOfSupply: finalPos,
        placeOfSupplyStateCode: finalPos != null ? _placeOfSupplyStateCode : null,
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
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(activeBusinessProvider);
        ref.invalidate(businessNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${saved.invoiceNumber} created successfully!'),
            backgroundColor: AppColors.successDark,
          ),
        );
        context.pushReplacement('/invoices/${saved.id}/preview');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invoice: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isGst ? 'Create GST Tax Invoice' : 'Create Non-GST Invoice'),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Interactive Step Progress Bar
            _buildStepHeader(),

            // 2. Active Step Content
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: _buildCurrentStepView(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // 3. Fixed Bottom Action Buttons
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepHeader() {
    final steps = ['Info', 'Client', 'Items', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = _currentStep > index;
          final isCurrent = _currentStep == index;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentStep = index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: isCurrent
                          ? AppColors.primary
                          : (isCompleted ? AppColors.primaryContainer : AppColors.surfaceVariant),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: AppColors.primary)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        steps[index],
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Info();
      case 1:
        return _buildStep2Customer();
      case 2:
        return _buildStep3Items();
      case 3:
      default:
        return _buildStep4Totals();
    }
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))],
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    AppButton(
                      label: 'Back',
                      variant: ButtonVariant.outline,
                      width: 90,
                      onPressed: () => setState(() => _currentStep--),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: AppButton(
                      label: _currentStep < 3
                          ? (_currentStep == 0
                              ? 'Next: Select Client'
                              : (_currentStep == 1 ? 'Next: Add Items' : 'Next: Review & Totals'))
                          : 'Generate & Preview Invoice PDF',
                      icon: _currentStep < 3 ? Icons.arrow_forward_rounded : Icons.picture_as_pdf_rounded,
                      isLoading: _isSubmitting,
                      onPressed: () {
                        if (_currentStep < 3) {
                          if (_currentStep == 1 && _selectedCustomer == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select or add a client first')),
                            );
                            return;
                          }
                          setState(() => _currentStep++);
                        } else {
                          _submitInvoice();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Invoice Type Selector (GST vs Non-GST)
        Text('Invoice Tax Regime', style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeSelectionCard(
                title: 'GST Tax Invoice',
                subtitle: 'Tax slabs, CGST/SGST/IGST & GSTIN',
                icon: Icons.account_balance_outlined,
                isSelected: _isGst,
                onTap: () {
                  if (!_isGst) {
                    setState(() {
                      _isGst = true;
                      if (_invoiceTitleController.text == 'BILL OF SUPPLY' || _invoiceTitleController.text == 'INVOICE') {
                        _invoiceTitleController.text = 'TAX INVOICE';
                      }
                      _recalculateAllItems();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeSelectionCard(
                title: 'Non-GST / Bill of Supply',
                subtitle: 'Exempt supply or simple 0% tax billing',
                icon: Icons.receipt_outlined,
                isSelected: !_isGst,
                onTap: () {
                  if (_isGst) {
                    setState(() {
                      _isGst = false;
                      if (_invoiceTitleController.text == 'TAX INVOICE') {
                        _invoiceTitleController.text = 'BILL OF SUPPLY';
                      }
                      _recalculateAllItems();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2. Editable Invoice Title
        AppTextField(
          label: 'Invoice Title / Document Header *',
          hint: 'e.g. TAX INVOICE, BILL OF SUPPLY, PROFORMA INVOICE',
          controller: _invoiceTitleController,
          prefixIcon: const Icon(Icons.title_rounded),
        ),
        const SizedBox(height: 8),
        // Title Preset Chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildPresetChip('TAX INVOICE'),
            _buildPresetChip('BILL OF SUPPLY'),
            _buildPresetChip('PROFORMA INVOICE'),
            _buildPresetChip('INVOICE'),
            _buildPresetChip('QUOTATION'),
          ],
        ),
        const SizedBox(height: 18),

        // 3. Invoice Number & Reference Number
        AppTextField(
          label: 'Invoice Number',
          controller: _invoiceNumberController,
          prefixIcon: const Icon(Icons.tag_rounded),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Reference / Purchase Order (PO) #',
          hint: 'e.g. PO-89421',
          controller: _referenceNumberController,
          prefixIcon: const Icon(Icons.receipt_long_outlined),
        ),
        const SizedBox(height: 16),

        // 4. Invoice Date
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedMd,
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          title: Text('Invoice Date', style: AppTypography.labelMedium),
          subtitle: Text(DateFormatter.format(_invoiceDate), style: AppTypography.headingSmall),
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
        const SizedBox(height: 12),

        // 5. Payment Due Date (with None option)
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedMd,
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Due Date', style: AppTypography.labelMedium),
              if (_dueDate != null)
                GestureDetector(
                  onTap: () => setState(() => _dueDate = null),
                  child: Text(
                    'Clear (None)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            _dueDate != null ? DateFormatter.format(_dueDate!) : 'None (No Due Date)',
            style: AppTypography.headingSmall.copyWith(
              color: _dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          trailing: const Icon(Icons.event_available_rounded, color: AppColors.primary),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _dueDate = picked);
          },
        ),
        const SizedBox(height: 12),

        // Due Date Quick Select Chips
        Text('Quick Payment Terms', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('None'),
              selected: _dueDate == null,
              onSelected: (_) => setState(() => _dueDate = null),
            ),
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

  Widget _buildTypeSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.5) : AppColors.surface,
          borderRadius: AppDimensions.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 22),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)
                else
                  const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String title) {
    final isSelected = _invoiceTitleController.text == title;
    return ActionChip(
      label: Text(title, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : null, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      backgroundColor: isSelected ? AppColors.primaryContainer : null,
      onPressed: () => setState(() => _invoiceTitleController.text = title),
    );
  }

  Widget _buildStep2Customer() {
    final customersAsync = ref.watch(customerListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Place of Supply Selector
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.roundedMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Place of Supply (POS)', style: AppTypography.labelLarge),
                  if (_placeOfSupply != null && _placeOfSupply != 'None / Not Applicable')
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _placeOfSupply = 'None / Not Applicable';
                          _placeOfSupplyStateCode = null;
                          _recalculateSupplyType();
                          _recalculateAllItems();
                        });
                      },
                      child: Text(
                        'Set to None',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select the state of consumption or choose "None" for non-GST/exempt supplies.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _placeOfSupply ?? (_selectedCustomer?.billingState ?? 'None / Not Applicable'),
                decoration: const InputDecoration(
                  labelText: 'Place of Supply State',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: _placeOfSupplyOptions.map((opt) {
                  final name = opt['name']!;
                  final code = opt['code']!;
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(code.isNotEmpty ? '$name ($code)' : name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final match = _placeOfSupplyOptions.firstWhere(
                      (e) => e['name'] == val,
                      orElse: () => {'name': val, 'code': ''},
                    );
                    setState(() {
                      _placeOfSupply = val;
                      _placeOfSupplyStateCode = match['code']!.isEmpty ? null : match['code'];
                      _recalculateSupplyType();
                      _recalculateAllItems();
                    });
                  }
                },
              ),
            ],
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Select Client', style: AppTypography.headingMedium)),
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Add Client'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () async {
                final added = await CustomerFormBottomSheet.show(context);
                if (added != null) {
                  setState(() {
                    _selectedCustomer = added;
                    if (_placeOfSupply == null || _placeOfSupply == 'None / Not Applicable') {
                      _placeOfSupply = added.billingState;
                      _placeOfSupplyStateCode = added.billingStateCode;
                    }
                    _recalculateSupplyType();
                    _recalculateAllItems();
                  });
                  ref.invalidate(customerListProvider);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        customersAsync.when(
          data: (customers) {
            if (customers.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimensions.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 44, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('No Customers Yet', style: AppTypography.headingSmall),
                    const SizedBox(height: 4),
                    Text('Add your first customer to bill this invoice to.', style: AppTypography.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Quick Add Client'),
                      onPressed: () async {
                        final added = await CustomerFormBottomSheet.show(context);
                        if (added != null) {
                          setState(() {
                            _selectedCustomer = added;
                            if (_placeOfSupply == null || _placeOfSupply == 'None / Not Applicable') {
                              _placeOfSupply = added.billingState;
                              _placeOfSupplyStateCode = added.billingStateCode;
                            }
                            _recalculateSupplyType();
                            _recalculateAllItems();
                          });
                          ref.invalidate(customerListProvider);
                        }
                      },
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: customers.map((c) {
                final isSelected = _selectedCustomer?.id == c.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected ? AppColors.primaryContainer : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.roundedMd,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedCustomer = c;
                        if (_placeOfSupply == null || _placeOfSupply == 'None / Not Applicable') {
                          _placeOfSupply = c.billingState;
                          _placeOfSupplyStateCode = c.billingStateCode;
                        }
                        _recalculateSupplyType();
                        _recalculateAllItems();
                      });
                    },
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                      child: Icon(Icons.person_rounded, color: isSelected ? Colors.white : AppColors.textSecondary),
                    ),
                    title: Text(c.companyName?.isNotEmpty == true ? c.companyName! : c.name, style: AppTypography.labelLarge),
                    subtitle: Text(
                      '${c.name} • ${c.billingCity ?? ""}, ${c.billingState} (Code ${c.billingStateCode ?? "N/A"})',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildStep3Items() {
    double runningSubtotal = 0;
    for (final it in _lineItems) {
      runningSubtotal += it.totalAmount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Actions
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('Invoice Items (${_lineItems.length})', style: AppTypography.headingMedium),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined, size: 15),
                  label: const Text('Catalog'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showAddCatalogItemModal(),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Custom'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showCustomItemModal(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Empty state when no items
        if (_lineItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.shopping_bag_outlined, size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text('No items added yet', style: AppTypography.headingMedium),
                const SizedBox(height: 6),
                Text(
                  'Add items from your saved catalog or create a custom line item for this invoice.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        label: const Text('From Catalog', overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                        ),
                        onPressed: () => _showAddCatalogItemModal(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Custom Item', overflow: TextOverflow.ellipsis),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                        ),
                        onPressed: () => _showCustomItemModal(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Render line items
        ..._lineItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.description, style: AppTypography.labelLarge)),
                      const SizedBox(width: 8),
                      Text(CurrencyFormatter.format(item.totalAmount), style: AppTypography.currencyMedium.copyWith(color: AppColors.primary)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _lineItems.removeAt(idx)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            _isGst
                                ? 'HSN: ${item.hsnSac ?? "N/A"}  |  GST: ${item.taxRate.toInt()}%'
                                : 'HSN: ${item.hsnSac ?? "N/A"}  |  Non-GST',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (item.quantity > 1) {
                                final newQty = item.quantity - 1;
                                final calc = GstCalculator.calculateLineItem(
                                  quantity: newQty,
                                  rate: item.rate,
                                  taxRate: item.taxRate,
                                  supplyType: _supplyType,
                                  isGst: _isGst,
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${item.quantity.toInt()} ${item.unit}', style: AppTypography.labelLarge),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              final newQty = item.quantity + 1;
                              final calc = GstCalculator.calculateLineItem(
                                quantity: newQty,
                                rate: item.rate,
                                taxRate: item.taxRate,
                                supplyType: _supplyType,
                                isGst: _isGst,
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

        if (_lineItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimensions.roundedMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items Total (${_lineItems.length})', style: AppTypography.labelMedium),
                Text(CurrencyFormatter.format(runningSubtotal), style: AppTypography.currencyMedium),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showCustomItemModal() {
    final nameCtrl = TextEditingController();
    final hsnCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    double taxRate = _isGst ? 18.0 : 0.0;
    String unit = 'PCS';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Custom Line Item', style: AppTypography.headingMedium),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Item Description / Name *', hint: 'e.g. Website Hosting Fee', controller: nameCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: AppTextField(label: 'HSN/SAC', hint: '998314', controller: hsnCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: AppTextField(label: 'Qty', keyboardType: TextInputType.number, controller: qtyCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: AppTextField(label: 'Rate (₹) *', keyboardType: TextInputType.number, controller: rateCtrl)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_isGst)
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
                        )
                      else
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppDimensions.roundedMd,
                            ),
                            child: Text('Tax: 0% (Non-GST)', style: AppTypography.labelMedium),
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
                            DropdownMenuItem(value: 'MTR', child: Text('MTR')),
                            DropdownMenuItem(value: 'PER', child: Text('PER')),
                            DropdownMenuItem(value: 'PAIR', child: Text('PAIR')),
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
                        taxRate: _isGst ? taxRate : 0.0,
                        supplyType: _supplyType,
                        isGst: _isGst,
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
                            taxRate: _isGst ? taxRate : 0.0,
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final repo = ref.read(itemRepositoryProvider);
        return FutureBuilder<List<ItemModel>>(
          future: repo.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
            }
            final items = snapshot.data!;

            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('Catalog is Empty', style: AppTypography.headingSmall),
                    const SizedBox(height: 6),
                    Text(
                      'You do not have any items saved in your catalog yet. You can add a custom item to this invoice directly.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Add Custom Item'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCustomItemModal();
                      },
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pick Item from Catalog', style: AppTypography.headingSmall),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.name, style: AppTypography.labelLarge),
                      subtitle: Text(
                        _isGst
                            ? 'HSN: ${item.hsnSac ?? "N/A"} • GST: ${item.taxRate.toInt()}%'
                            : 'HSN: ${item.hsnSac ?? "N/A"} • Non-GST',
                      ),
                      trailing: Text(CurrencyFormatter.format(item.rate), style: AppTypography.currencySmall),
                      onTap: () {
                        final calc = GstCalculator.calculateLineItem(
                          quantity: 1,
                          rate: item.rate,
                          taxRate: _isGst ? item.taxRate : 0.0,
                          supplyType: _supplyType,
                          isGst: _isGst,
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
                              taxRate: _isGst ? item.taxRate : 0.0,
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
        // Supply Type Selector Card (Only relevant for GST)
        if (_isGst)
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
                      _supplyType == GstSupplyType.intraState ? 'Intra-State (CGST + SGST)' : 'Inter-State (IGST)',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                Switch(
                  value: _supplyType == GstSupplyType.interState,
                  onChanged: (val) {
                    setState(() {
                      _supplyType = val ? GstSupplyType.interState : GstSupplyType.intraState;
                      _recalculateAllItems();
                    });
                  },
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppDimensions.roundedMd,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Non-GST Mode: Tax rate is set to 0% with no CGST/SGST/IGST breakdown.',
                    style: AppTypography.bodySmall,
                  ),
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
                decoration: const InputDecoration(labelText: 'Invoice Discount (₹)', prefixText: '₹ '),
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
                _buildSummaryRow(_isGst ? 'Taxable Value' : 'Net Amount', totals.taxableAmount),
                const Divider(height: 20),
                if (_isGst) ...[
                  if (_supplyType == GstSupplyType.intraState) ...[
                    _buildSummaryRow('CGST', totals.totalCgst),
                    _buildSummaryRow('SGST', totals.totalSgst),
                  ] else ...[
                    _buildSummaryRow('IGST', totals.totalIgst),
                  ],
                  const Divider(height: 20),
                ],
                if (totals.roundOff != 0) _buildSummaryRow('Round Off', totals.roundOff),
                _buildSummaryRow('Grand Total', totals.grandTotal, isBold: true, fontSize: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
