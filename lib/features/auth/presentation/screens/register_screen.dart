import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedState = 'Maharashtra';
  String _selectedStateCode = '27';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        businessName: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
        state: _selectedState,
        stateCode: _selectedStateCode,
      );

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDimensions.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text('Get Started with Invoicify', style: AppTypography.headingLarge),
                const SizedBox(height: 4),
                Text(
                  'Create GST-compliant invoices in under 60 seconds.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                AppTextField(
                  label: 'Full Name *',
                  hint: 'e.g. Mukund Sharma',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Business / Company Name *',
                  hint: 'e.g. Apex Solutions Pvt Ltd',
                  controller: _businessNameController,
                  prefixIcon: const Icon(Icons.business_rounded, size: 20),
                  validator: (v) => Validators.required(v, 'Business Name'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Work Email *',
                  hint: 'name@company.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Phone Number *',
                  hint: '+91 9876543210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedStateCode,
                  decoration: const InputDecoration(
                    labelText: 'Registered State (for GST)',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
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
                        _selectedStateCode = v;
                        if (v == '27') _selectedState = 'Maharashtra';
                        if (v == '07') _selectedState = 'Delhi';
                        if (v == '29') _selectedState = 'Karnataka';
                        if (v == '33') _selectedState = 'Tamil Nadu';
                        if (v == '24') _selectedState = 'Gujarat';
                        if (v == '36') _selectedState = 'Telangana';
                        if (v == '09') _selectedState = 'Uttar Pradesh';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Password *',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                AppButton(
                  label: 'Create Free Account',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: AppTypography.bodySmall),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sign In',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
