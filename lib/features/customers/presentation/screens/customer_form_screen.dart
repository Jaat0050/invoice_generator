import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_detail_screen.dart';
import 'customer_list_screen.dart';

/// Full-screen wrapper for customer creation/editing
class CustomerFormScreen extends StatelessWidget {
  final CustomerModel? initialCustomer;

  const CustomerFormScreen({super.key, this.initialCustomer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(initialCustomer != null ? 'Edit Customer' : 'Add New Customer'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: CustomerFormBottomSheet(
            initialCustomer: initialCustomer,
            isBottomSheet: false,
          ),
        ),
      ),
    );
  }
}

class CustomerFormBottomSheet extends ConsumerStatefulWidget {
  final CustomerModel? initialCustomer;
  final bool isBottomSheet;

  const CustomerFormBottomSheet({
    super.key,
    this.initialCustomer,
    this.isBottomSheet = true,
  });

  static Future<CustomerModel?> show(BuildContext context, {CustomerModel? initialCustomer}) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CustomerFormBottomSheet(initialCustomer: initialCustomer),
    );
  }

  @override
  ConsumerState<CustomerFormBottomSheet> createState() => _CustomerFormBottomSheetState();
}

class _CustomerFormBottomSheetState extends ConsumerState<CustomerFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _gstinCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  String _selectedState = 'Maharashtra';
  String _selectedStateCode = '27';
  late final List<Map<String, String>> _indianStates;
  bool _isLoading = false;

  static const List<Map<String, String>> _defaultIndianStates = [
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
    {'name': 'None / Not Applicable', 'code': ''},
  ];

  @override
  void initState() {
    super.initState();
    _indianStates = List.from(_defaultIndianStates);
    final c = widget.initialCustomer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _companyCtrl = TextEditingController(text: c?.companyName ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _gstinCtrl = TextEditingController(text: c?.gstin ?? '');
    _addressCtrl = TextEditingController(text: c?.billingAddress ?? '');
    _cityCtrl = TextEditingController(text: c?.billingCity ?? '');
    if (c != null && c.billingState.isNotEmpty) {
      final exists = _indianStates.any((e) => e['name']?.toLowerCase() == c.billingState.toLowerCase());
      if (!exists) {
        _indianStates.add({'name': c.billingState, 'code': c.billingStateCode ?? ''});
      }
      final matched = _indianStates.firstWhere(
        (e) => e['name']?.toLowerCase() == c.billingState.toLowerCase(),
        orElse: () => {'name': c.billingState, 'code': c.billingStateCode ?? '27'},
      );
      _selectedState = matched['name']!;
      _selectedStateCode = matched['code'] ?? c.billingStateCode ?? '27';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = CustomerModel(
        id: widget.initialCustomer?.id ?? 0,
        businessId: widget.initialCustomer?.businessId ?? 1,
        name: _nameCtrl.text.trim(),
        companyName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim().toUpperCase(),
        pan: widget.initialCustomer?.pan,
        billingAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        billingCity: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        billingState: _selectedState,
        billingStateCode: _selectedStateCode.isEmpty ? null : _selectedStateCode,
        billingPincode: widget.initialCustomer?.billingPincode,
        shippingAddress: widget.initialCustomer?.shippingAddress,
        totalSales: widget.initialCustomer?.totalSales ?? 0.0,
        totalPaid: widget.initialCustomer?.totalPaid ?? 0.0,
        outstandingAmount: widget.initialCustomer?.outstandingAmount ?? 0.0,
        createdAt: widget.initialCustomer?.createdAt,
      );

      final CustomerModel saved;
      if (widget.initialCustomer != null) {
        saved = await repo.updateCustomer(customer);
      } else {
        saved = await repo.addCustomer(customer);
      }

      if (mounted) {
        ref.invalidate(customerListProvider);
        if (widget.initialCustomer != null) {
          ref.invalidate(customerDetailProvider(widget.initialCustomer!.id));
        }
        Navigator.pop(context, saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save customer: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: AppColors.errorDark,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.isBottomSheet ? 20 : 0,
        right: widget.isBottomSheet ? 20 : 0,
        top: widget.isBottomSheet ? 16 : 0,
        bottom: widget.isBottomSheet ? (MediaQuery.of(context).viewInsets.bottom + 20) : 0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isBottomSheet) ...[
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialCustomer != null ? 'Edit Customer' : 'Add New Customer',
                      style: AppTypography.headingMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  widget.initialCustomer != null ? 'Edit Customer Details' : 'Customer Information',
                  style: AppTypography.headingMedium,
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Contact Person Name',
                hint: 'e.g. Ramesh Kumar',
                controller: _nameCtrl,
                validator: (v) => Validators.required(v, 'Name is required'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Company / Trade Name (Optional)',
                hint: 'e.g. Acme Innovations Pvt Ltd',
                controller: _companyCtrl,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Phone Number',
                      hint: '9876543210',
                      keyboardType: TextInputType.phone,
                      controller: _phoneCtrl,
                      validator: (v) => Validators.required(v) ?? Validators.phone(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Email (Optional)',
                      hint: 'billing@client.com',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailCtrl,
                      validator: (v) => Validators.email(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'GSTIN (Optional for unregistered buyers)',
                hint: '27AABCA1234F1Z5',
                controller: _gstinCtrl,
                validator: (v) => Validators.gstin(v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'State / POS',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _indianStates.map((st) {
                        final code = st['code'] ?? '';
                        return DropdownMenuItem<String>(
                          value: st['name'],
                          child: Text(
                            code.isNotEmpty ? '${st['name']} ($code)' : st['name']!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final match = _indianStates.firstWhere(
                            (e) => e['name'] == v,
                            orElse: () => {'name': v, 'code': ''},
                          );
                          setState(() {
                            _selectedState = v;
                            _selectedStateCode = match['code'] ?? '';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'City',
                      hint: 'e.g. Mumbai',
                      controller: _cityCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Billing Address',
                hint: 'Street, Building, Area, Pincode',
                controller: _addressCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: widget.initialCustomer != null ? 'Update Customer' : 'Save Customer',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
