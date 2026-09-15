import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
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
        bool hasActiveSession = false;
        if (SupabaseConfig.isConfigured) {
          try {
            hasActiveSession = Supabase.instance.client.auth.currentSession != null;
          } catch (_) {}
        }

        if (hasActiveSession) {
          context.go('/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please check your email to confirm if needed, then sign in.'),
              duration: Duration(seconds: 4),
            ),
          );
          context.go('/login');
        }
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
          child: ResponsiveWrapper(
            maxWidth: 520,
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
                    hint: 'e.g. Acme Enterprises Pvt Ltd',
                    controller: _businessNameController,
                    prefixIcon: const Icon(Icons.business_rounded, size: 20),
                    validator: (v) => Validators.required(v, 'Business Name'),
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Work Email *',
                    hint: 'name@business.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    validator: (v) => Validators.required(v) ?? Validators.email(v),
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Phone Number (Optional)',
                    hint: '9876543210',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 16),

                  // State Selector for GST State Code
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: const InputDecoration(
                      labelText: 'Business State (for GST) *',
                      prefixIcon: Icon(Icons.map_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Maharashtra', child: Text('Maharashtra (27)')),
                      DropdownMenuItem(value: 'Delhi', child: Text('Delhi (07)')),
                      DropdownMenuItem(value: 'Karnataka', child: Text('Karnataka (29)')),
                      DropdownMenuItem(value: 'Tamil Nadu', child: Text('Tamil Nadu (33)')),
                      DropdownMenuItem(value: 'Gujarat', child: Text('Gujarat (24)')),
                      DropdownMenuItem(value: 'Uttar Pradesh', child: Text('Uttar Pradesh (09)')),
                      DropdownMenuItem(value: 'Telangana', child: Text('Telangana (36)')),
                      DropdownMenuItem(value: 'West Bengal', child: Text('West Bengal (19)')),
                      DropdownMenuItem(value: 'Rajasthan', child: Text('Rajasthan (08)')),
                      DropdownMenuItem(value: 'Haryana', child: Text('Haryana (06)')),
                      DropdownMenuItem(value: 'Kerala', child: Text('Kerala (32)')),
                      DropdownMenuItem(value: 'Madhya Pradesh', child: Text('Madhya Pradesh (23)')),
                      DropdownMenuItem(value: 'Punjab', child: Text('Punjab (03)')),
                      DropdownMenuItem(value: 'Bihar', child: Text('Bihar (10)')),
                      DropdownMenuItem(value: 'Andhra Pradesh', child: Text('Andhra Pradesh (37)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedState = val;
                          final stateCodes = {
                            'Jammu & Kashmir': '01', 'Himachal Pradesh': '02', 'Punjab': '03',
                            'Chandigarh': '04', 'Uttarakhand': '05', 'Haryana': '06',
                            'Delhi': '07', 'Rajasthan': '08', 'Uttar Pradesh': '09',
                            'Bihar': '10', 'West Bengal': '19', 'Gujarat': '24',
                            'Maharashtra': '27', 'Karnataka': '29', 'Kerala': '32',
                            'Tamil Nadu': '33', 'Telangana': '36', 'Andhra Pradesh': '37',
                            'Madhya Pradesh': '23',
                          };
                          _selectedStateCode = stateCodes[val] ?? '27';
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
      ),
    );
  }
}
