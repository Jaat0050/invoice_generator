import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/image_upload_card.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class BusinessSetupWizardScreen extends ConsumerStatefulWidget {
  const BusinessSetupWizardScreen({super.key});

  @override
  ConsumerState<BusinessSetupWizardScreen> createState() => _BusinessSetupWizardScreenState();
}

class _BusinessSetupWizardScreenState extends ConsumerState<BusinessSetupWizardScreen> {
  int _currentStep = 0;

  // Step 1: Business info
  final _businessNameCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _stateCode = '27';
  String _stateName = 'Maharashtra';
  String? _logoUrl;
  String? _signatureUrl;

  // Step 2: Payment details
  final _upiCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  // Step 3: Prefix & Sequence
  final _prefixCtrl = TextEditingController(text: 'INV-');
  final _sequenceCtrl = TextEditingController(text: '1001');

  bool _isSaving = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _gstinCtrl.dispose();
    _cityCtrl.dispose();
    _upiCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _prefixCtrl.dispose();
    _sequenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final current = await repo.getActiveBusiness();
      final updated = current.copyWith(
        name: _businessNameCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim().toUpperCase(),
        city: _cityCtrl.text.trim(),
        state: _stateName,
        stateCode: _stateCode,
        logoUrl: _logoUrl,
        signatureUrl: _signatureUrl,
        upiId: _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim().isEmpty ? null : _bankNameCtrl.text.trim(),
        bankAccountNumber: _accountNumberCtrl.text.trim().isEmpty ? null : _accountNumberCtrl.text.trim(),
        bankIfsc: _ifscCtrl.text.trim().isEmpty ? null : _ifscCtrl.text.trim().toUpperCase(),
        invoicePrefix: _prefixCtrl.text.trim().isEmpty ? 'INV-' : _prefixCtrl.text.trim(),
        nextInvoiceNumber: int.tryParse(_sequenceCtrl.text.trim()) ?? 1001,
      );

      await ref.read(businessNotifierProvider.notifier).updateBusiness(updated);
      ref.invalidate(activeBusinessProvider);

      if (mounted) {
        context.go('/dashboard');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Setup Your Business'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.surface,
              child: Row(
                children: [
                  _buildStepBubble(0, 'Profile'),
                  _buildStepLine(0),
                  _buildStepBubble(1, 'Payments'),
                  _buildStepLine(1),
                  _buildStepBubble(2, 'Invoicing'),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: AppDimensions.pagePadding,
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Back',
                        variant: ButtonVariant.outline,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _currentStep == 2 ? 'Finish & Launch' : 'Continue',
                      icon: _currentStep == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                      isLoading: _isSaving,
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _completeSetup();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone
              ? AppColors.success
              : (isActive ? AppColors.primary : AppColors.border),
          child: isDone
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.textMuted,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isPassed = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isPassed ? AppColors.success : AppColors.border,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 1: Business Identity', style: AppTypography.headingMedium),
            const SizedBox(height: 4),
            Text('Set up your company details for tax invoices.', style: AppTypography.bodySmall),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Business / Trade Name *',
              hint: 'e.g. Acme Enterprises',
              controller: _businessNameCtrl,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'GSTIN (Optional)',
              hint: '27AABCA1234F1Z5',
              controller: _gstinCtrl,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'City',
              hint: 'Mumbai',
              controller: _cityCtrl,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _stateCode,
              decoration: const InputDecoration(labelText: 'Primary State of Operations'),
              items: const [
                DropdownMenuItem(value: '27', child: Text('27 - Maharashtra')),
                DropdownMenuItem(value: '07', child: Text('07 - Delhi')),
                DropdownMenuItem(value: '29', child: Text('29 - Karnataka')),
                DropdownMenuItem(value: '33', child: Text('33 - Tamil Nadu')),
                DropdownMenuItem(value: '24', child: Text('24 - Gujarat')),
                DropdownMenuItem(value: '36', child: Text('36 - Telangana')),
                DropdownMenuItem(value: '09', child: Text('09 - Uttar Pradesh')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _stateCode = v;
                    if (v == '27') _stateName = 'Maharashtra';
                    if (v == '07') _stateName = 'Delhi';
                    if (v == '29') _stateName = 'Karnataka';
                    if (v == '33') _stateName = 'Tamil Nadu';
                    if (v == '24') _stateName = 'Gujarat';
                    if (v == '36') _stateName = 'Telangana';
                    if (v == '09') _stateName = 'Uttar Pradesh';
                  });
                }
              },
            ),
            const SizedBox(height: 18),
            ImageUploadCard(
              title: 'Company Logo',
              subtitle: 'Optional branding for invoice header.',
              currentUrl: _logoUrl,
              onImageUpdated: (url) => setState(() => _logoUrl = url),
            ),
            const SizedBox(height: 12),
            ImageUploadCard(
              title: 'Authorized Signature *',
              subtitle: 'Mandatory signature for all tax invoices.',
              isSignature: true,
              currentUrl: _signatureUrl,
              onImageUpdated: (url) => setState(() => _signatureUrl = url),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 2: Payment Details', style: AppTypography.headingMedium),
            const SizedBox(height: 4),
            Text('Enter accounts where clients will pay invoices.', style: AppTypography.bodySmall),
            const SizedBox(height: 20),
            AppTextField(
              label: 'UPI ID for QR Code',
              hint: 'company@icici',
              controller: _upiCtrl,
              prefixIcon: const Icon(Icons.qr_code_2_rounded),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Bank Name',
              hint: 'HDFC Bank',
              controller: _bankNameCtrl,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Account Number',
              hint: '50200012345678',
              controller: _accountNumberCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'IFSC Code',
              hint: 'HDFC0001234',
              controller: _ifscCtrl,
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 3: Invoice Numbering', style: AppTypography.headingMedium),
            const SizedBox(height: 4),
            Text('Configure standard prefixes and starting numbers.', style: AppTypography.bodySmall),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Invoice Prefix',
              hint: 'INV-',
              controller: _prefixCtrl,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Starting Invoice Number',
              hint: '1001',
              controller: _sequenceCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppDimensions.roundedMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preview: Your first invoice will be ${_prefixCtrl.text}${_sequenceCtrl.text}',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
