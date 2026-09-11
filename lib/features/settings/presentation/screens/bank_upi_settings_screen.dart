import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/data/models/business_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class BankUpiSettingsScreen extends ConsumerStatefulWidget {
  const BankUpiSettingsScreen({super.key});

  @override
  ConsumerState<BankUpiSettingsScreen> createState() => _BankUpiSettingsScreenState();
}

class _BankUpiSettingsScreenState extends ConsumerState<BankUpiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _upiIdController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _branchController;

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _upiIdController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _ifscController = TextEditingController();
    _branchController = TextEditingController();
  }

  void _populateData(BusinessModel business) {
    if (_isInitialized) return;
    _upiIdController.text = business.upiId ?? '';
    _bankNameController.text = business.bankName ?? '';
    _accountNumberController.text = business.bankAccountNumber ?? '';
    _ifscController.text = business.bankIfsc ?? '';
    _branchController.text = business.bankBranch ?? '';
    _isInitialized = true;
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings(BusinessModel current) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updated = current.copyWith(
        upiId: _upiIdController.text.trim().isEmpty ? null : _upiIdController.text.trim(),
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        bankAccountNumber: _accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim(),
        bankIfsc: _ifscController.text.trim().isEmpty ? null : _ifscController.text.trim().toUpperCase(),
        bankBranch: _branchController.text.trim().isEmpty ? null : _branchController.text.trim(),
      );

      await ref.read(businessNotifierProvider.notifier).updateBusiness(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment & Bank details updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update payment details: $e')),
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
        title: const Text('Bank & UPI Accounts'),
      ),
      body: businessAsync.when(
        data: (business) {
          _populateData(business);

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppDimensions.pagePadding,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppDimensions.roundedLg,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant Dynamic UPI QR Codes',
                              style: AppTypography.headingSmall.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your UPI ID and Bank information will be printed directly onto your PDF invoices.',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // UPI Configuration
                _buildSectionHeader('UPI Payment Details'),
                AppTextField(
                  label: 'UPI Virtual Payment Address (VPA) *',
                  hint: 'companyname@icici or 9876543210@paytm',
                  controller: _upiIdController,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) {
                      return 'Enter a valid UPI ID (e.g. name@bank)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.lg),

                // Bank Account Details
                _buildSectionHeader('Direct Bank Transfer (NEFT / RTGS / IMPS)'),
                AppTextField(
                  label: 'Bank Name',
                  hint: 'e.g. HDFC Bank, ICICI Bank, SBI',
                  controller: _bankNameController,
                  prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Account Number',
                  hint: '50200012345678',
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'IFSC Code (11 Chars)',
                        hint: 'HDFC0001234',
                        controller: _ifscController,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length != 11) {
                            return 'IFSC must be 11 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Branch Name',
                        hint: 'e.g. BKC Branch',
                        controller: _branchController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),

                // Save Button
                AppButton(
                  label: 'Save Bank & UPI Settings',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: () => _saveSettings(business),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

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
