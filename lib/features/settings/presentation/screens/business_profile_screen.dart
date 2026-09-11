import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/data/models/business_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _legalNameController;
  late TextEditingController _gstinController;
  late TextEditingController _panController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _prefixController;
  late TextEditingController _nextNumberController;

  String _selectedStateCode = '27';
  String _selectedStateName = 'Maharashtra';
  bool _isSaving = false;
  bool _isInitialized = false;

  static const List<Map<String, String>> _indianStates = [
    {'code': '01', 'name': 'Jammu and Kashmir'},
    {'code': '02', 'name': 'Himachal Pradesh'},
    {'code': '03', 'name': 'Punjab'},
    {'code': '04', 'name': 'Chandigarh'},
    {'code': '05', 'name': 'Uttarakhand'},
    {'code': '06', 'name': 'Haryana'},
    {'code': '07', 'name': 'Delhi'},
    {'code': '08', 'name': 'Rajasthan'},
    {'code': '09', 'name': 'Uttar Pradesh'},
    {'code': '10', 'name': 'Bihar'},
    {'code': '11', 'name': 'Sikkim'},
    {'code': '12', 'name': 'Arunachal Pradesh'},
    {'code': '13', 'name': 'Nagaland'},
    {'code': '14', 'name': 'Manipur'},
    {'code': '15', 'name': 'Mizoram'},
    {'code': '16', 'name': 'Tripura'},
    {'code': '17', 'name': 'Meghalaya'},
    {'code': '18', 'name': 'Assam'},
    {'code': '19', 'name': 'West Bengal'},
    {'code': '20', 'name': 'Jharkhand'},
    {'code': '21', 'name': 'Odisha'},
    {'code': '22', 'name': 'Chhattisgarh'},
    {'code': '23', 'name': 'Madhya Pradesh'},
    {'code': '24', 'name': 'Gujarat'},
    {'code': '26', 'name': 'Dadra and Nagar Haveli and Daman and Diu'},
    {'code': '27', 'name': 'Maharashtra'},
    {'code': '28', 'name': 'Andhra Pradesh'},
    {'code': '29', 'name': 'Karnataka'},
    {'code': '30', 'name': 'Goa'},
    {'code': '31', 'name': 'Lakshadweep'},
    {'code': '32', 'name': 'Kerala'},
    {'code': '33', 'name': 'Tamil Nadu'},
    {'code': '34', 'name': 'Puducherry'},
    {'code': '35', 'name': 'Andaman and Nicobar Islands'},
    {'code': '36', 'name': 'Telangana'},
    {'code': '37', 'name': 'Andhra Pradesh (New)'},
    {'code': '38', 'name': 'Ladakh'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _legalNameController = TextEditingController();
    _gstinController = TextEditingController();
    _panController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _pincodeController = TextEditingController();
    _prefixController = TextEditingController();
    _nextNumberController = TextEditingController();
  }

  void _populateData(BusinessModel business) {
    if (_isInitialized) return;
    _nameController.text = business.name;
    _legalNameController.text = business.legalName ?? '';
    _gstinController.text = business.gstin ?? '';
    _panController.text = business.pan ?? '';
    _emailController.text = business.email ?? '';
    _phoneController.text = business.phone ?? '';
    _addressController.text = business.address ?? '';
    _cityController.text = business.city ?? '';
    _pincodeController.text = business.pincode ?? '';
    _prefixController.text = business.invoicePrefix;
    _nextNumberController.text = business.nextInvoiceNumber.toString();

    _selectedStateCode = business.stateCode ?? '27';
    _selectedStateName = business.state;
    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  void _onGstinChanged(String gstin) {
    final clean = gstin.trim().toUpperCase();
    if (clean.length >= 2) {
      final code = clean.substring(0, 2);
      final match = _indianStates.firstWhere(
        (s) => s['code'] == code,
        orElse: () => {'code': code, 'name': _selectedStateName},
      );
      setState(() {
        _selectedStateCode = match['code']!;
        _selectedStateName = match['name']!;
      });
    }
    if (clean.length >= 12 && _panController.text.isEmpty) {
      final pan = clean.substring(2, 12);
      _panController.text = pan;
    }
  }

  Future<void> _saveBusinessProfile(BusinessModel current) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updated = current.copyWith(
        name: _nameController.text.trim(),
        legalName: _legalNameController.text.trim().isEmpty ? null : _legalNameController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim().toUpperCase(),
        pan: _panController.text.trim().isEmpty ? null : _panController.text.trim().toUpperCase(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _selectedStateName,
        stateCode: _selectedStateCode,
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        invoicePrefix: _prefixController.text.trim().isEmpty ? 'INV-' : _prefixController.text.trim(),
        nextInvoiceNumber: int.tryParse(_nextNumberController.text.trim()) ?? current.nextInvoiceNumber,
      );

      await ref.read(businessNotifierProvider.notifier).updateBusiness(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update business profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Business Profile'),
      ),
      body: businessAsync.when(
        data: (business) {
          _populateData(business);

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppDimensions.pagePadding,
              children: [
                // Branding Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: AppDimensions.roundedMd,
                          ),
                          child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(business.name, style: AppTypography.headingSmall),
                              const SizedBox(height: 2),
                              Text(
                                'State: $selectedStateLabel',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // General Information
                _buildSectionHeader('General Information'),
                AppTextField(
                  label: 'Trade / Brand Name *',
                  hint: 'e.g. Apex Solutions',
                  controller: _nameController,
                  validator: (v) => Validators.required(v, 'Business Name'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Legal Registered Name',
                  hint: 'e.g. Apex Solutions Private Limited',
                  controller: _legalNameController,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'GSTIN (15 Digits)',
                        hint: '27AABCA1234F1Z5',
                        controller: _gstinController,
                        onChanged: _onGstinChanged,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return Validators.gstin(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'PAN Number',
                        hint: 'AABCA1234F',
                        controller: _panController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return Validators.pan(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Business Email',
                        hint: 'billing@company.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return Validators.email(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Phone Number',
                        hint: '+91 9876543210',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),

                // Address & State
                _buildSectionHeader('Billing Address & Place of Supply'),
                AppTextField(
                  label: 'Registered Street Address',
                  hint: 'Suite 402, Trade Tower, BKC',
                  controller: _addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'City',
                        hint: 'Mumbai',
                        controller: _cityController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Pincode',
                        hint: '400051',
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _indianStates.any((s) => s['code'] == _selectedStateCode) ? _selectedStateCode : '27',
                  decoration: const InputDecoration(labelText: 'GST State / UT Code *'),
                  isExpanded: true,
                  items: _indianStates.map((s) {
                    return DropdownMenuItem(
                      value: s['code'],
                      child: Text('${s['code']} - ${s['name']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final item = _indianStates.firstWhere((s) => s['code'] == val);
                      setState(() {
                        _selectedStateCode = val;
                        _selectedStateName = item['name']!;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppDimensions.lg),

                // Invoice Sequence Config
                _buildSectionHeader('Invoice Numbering & Prefix'),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Invoice Prefix',
                        hint: 'INV-',
                        controller: _prefixController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Next Invoice Number',
                        hint: '1001',
                        controller: _nextNumberController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),

                // Save Button
                AppButton(
                  label: 'Save Business Profile',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: () => _saveBusinessProfile(business),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading business: $err')),
      ),
    );
  }

  String get selectedStateLabel => '$_selectedStateCode - $_selectedStateName';

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
