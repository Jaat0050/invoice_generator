import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_list_screen.dart';

class CustomerFormBottomSheet extends ConsumerStatefulWidget {
  final CustomerModel? initialCustomer;

  const CustomerFormBottomSheet({super.key, this.initialCustomer});

  static Future<CustomerModel?> show(BuildContext context, {CustomerModel? initialCustomer}) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
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

  final List<Map<String, String>> _indianStates = const [
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
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initialCustomer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _companyCtrl = TextEditingController(text: c?.companyName ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _gstinCtrl = TextEditingController(text: c?.gstin ?? '');
    _addressCtrl = TextEditingController(text: c?.billingAddress ?? '');
    _cityCtrl = TextEditingController(text: c?.billingCity ?? '');
    if (c != null) {
      _selectedState = c.billingState;
      _selectedStateCode = c.billingStateCode ?? '27';
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

    final repo = ref.read(customerRepositoryProvider);
    final customer = CustomerModel(
      id: widget.initialCustomer?.id ?? 0,
      businessId: 1,
      name: _nameCtrl.text.trim(),
      companyName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim().toUpperCase(),
      billingAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      billingCity: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      billingState: _selectedState,
      billingStateCode: _selectedStateCode,
    );

    final saved = await repo.addCustomer(customer);
    if (mounted) {
      ref.invalidate(customerListProvider);
      Navigator.pop(context, saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialCustomer != null ? 'Edit Customer' : 'Add New Customer',
                style: AppTypography.headingMedium,
              ),
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
                      decoration: const InputDecoration(labelText: 'Place of Supply (State)'),
                      items: _indianStates.map((st) {
                        return DropdownMenuItem<String>(
                          value: st['name'],
                          child: Text('${st['name']} (${st['code']})'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final match = _indianStates.firstWhere((e) => e['name'] == v);
                          setState(() {
                            _selectedState = v;
                            _selectedStateCode = match['code']!;
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
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Customer',
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
