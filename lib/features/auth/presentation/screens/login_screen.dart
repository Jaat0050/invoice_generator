import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';

import '../../../../core/widgets/responsive_wrapper.dart';

class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) => state = val;
}

final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(AuthLoadingNotifier.new);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.login(email: _emailController.text.trim(), password: _passwordController.text);
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('email_not_confirmed') || msg.contains('Email not confirmed')) {
          msg = 'Email not confirmed yet. Please verify your email.';
        } else if (msg.contains('Invalid login credentials')) {
          msg = 'Invalid email or password. Please check your credentials.';
        } else if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        } else if (msg.startsWith('AuthApiException: ')) {
          msg = msg.substring(18);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ResponsiveWrapper(
              maxWidth: 480,
              child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon & Header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: AppDimensions.roundedXl,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x334F46E5),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppDimensions.roundedXl,
                        child: Image.asset(
                          'assets/images/inv-app-icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(AppStrings.appName, style: AppTypography.displayLarge.copyWith(fontSize: 28), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(AppStrings.loginSubtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 36),

                  // Email Field
                  AppTextField(label: 'Email Address', hint: 'name@business.com', controller: _emailController, keyboardType: TextInputType.emailAddress, prefixIcon: const Icon(Icons.email_outlined), validator: (v) => Validators.required(v) ?? Validators.email(v)),
                  const SizedBox(height: 16),

                  // Password Field
                  AppTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    validator: (v) => Validators.required(v, 'Please enter your password'),
                  ),
                  const SizedBox(height: 24),

                  // Forgot Password Link
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text('Forgot Password?', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)))),
                  const SizedBox(height: 12),

                  // Submit Button
                  AppButton(label: 'Sign In', isLoading: isLoading, onPressed: _handleLogin),
                  const SizedBox(height: 16),

                  // Register link
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Don't have an account? ", style: AppTypography.bodySmall), GestureDetector(onTap: () => context.push('/register'), child: Text('Create One', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)))]),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
