import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('More Options'),
      ),
      body: ResponsiveWrapper(
        maxWidth: 800,
        child: ListView(
        padding: AppDimensions.pagePadding,
        children: [
          // Business Card
          InkWell(
            onTap: () => context.push('/business-profile'),
            borderRadius: AppDimensions.roundedLg,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.roundedLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryContainer,
                    child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: businessAsync.when(
                      data: (business) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: AppTypography.headingSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            business.gstin != null ? 'GSTIN: ${business.gstin}' : 'Tap to complete profile',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      loading: () => const Text('Loading business...'),
                      error: (_, __) => const Text('My Business'),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Menu Sections
          _buildSectionHeader('Management'),
          _buildMenuItem(
            icon: Icons.inventory_2_outlined,
            title: 'Items & Services',
            subtitle: 'Products, HSN/SAC codes & tax rates',
            onTap: () => context.push('/items'),
          ),
          _buildMenuItem(
            icon: Icons.payments_outlined,
            title: 'Payment History',
            subtitle: 'Recorded transactions and settlements',
            onTap: () => context.push('/payments'),
          ),
          _buildMenuItem(
            icon: Icons.analytics_outlined,
            title: 'Reports & Analytics',
            subtitle: 'Sales, GST tax summary & export',
            onTap: () => context.push('/reports'),
          ),

          const SizedBox(height: AppDimensions.md),
          _buildSectionHeader('Customization & Settings'),
          _buildMenuItem(
            icon: Icons.palette_outlined,
            title: 'Invoice Templates',
            subtitle: 'Customize theme colors, layout & branding',
            onTap: () => context.push('/templates'),
          ),
          _buildMenuItem(
            icon: Icons.account_balance_outlined,
            title: 'Bank & UPI Details',
            subtitle: 'Manage payment accounts & QR codes',
            onTap: () => context.push('/bank-settings'),
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'App Preferences & Defaults',
            subtitle: 'Terms template, currency, auto round-off',
            onTap: () => context.push('/app-settings'),
          ),

          const SizedBox(height: AppDimensions.lg),
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Sign Out',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
            onTap: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: AppDimensions.roundedSm,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: AppTypography.labelLarge),
        subtitle: Text(subtitle, style: AppTypography.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }
}
