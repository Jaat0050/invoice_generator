import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/typography.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../invoices/presentation/screens/invoice_detail_screen.dart';
import '../../../invoices/utils/pdf_invoice_generator.dart';
import '../../data/models/template_config_model.dart';

class TemplateConfigNotifier extends Notifier<TemplateConfigModel> {
  @override
  TemplateConfigModel build() => const TemplateConfigModel();

  void updateConfig(TemplateConfigModel config) => state = config;

  void setTemplateId(String templateId) {
    state = state.copyWith(templateId: templateId);
  }

  void setPrimaryColor(int colorHex) {
    state = state.copyWith(primaryColorHex: colorHex);
  }

  void toggleOption({
    bool? showLogo,
    bool? showGstin,
    bool? showCustomerGstin,
    bool? showHsnSac,
    bool? showBankDetails,
    bool? showUpiQr,
    bool? showSignature,
    bool? showTerms,
    bool? showPaymentDueAlert,
  }) {
    state = state.copyWith(
      showLogo: showLogo,
      showGstin: showGstin,
      showCustomerGstin: showCustomerGstin,
      showHsnSac: showHsnSac,
      showBankDetails: showBankDetails,
      showUpiQr: showUpiQr,
      showSignature: showSignature,
      showTerms: showTerms,
      showPaymentDueAlert: showPaymentDueAlert,
    );
  }
}

final templateConfigProvider =
    NotifierProvider<TemplateConfigNotifier, TemplateConfigModel>(TemplateConfigNotifier.new);

class TemplateSelectorScreen extends ConsumerStatefulWidget {
  final int? invoiceId;

  const TemplateSelectorScreen({super.key, this.invoiceId});

  @override
  ConsumerState<TemplateSelectorScreen> createState() => _TemplateSelectorScreenState();
}

class _TemplateSelectorScreenState extends ConsumerState<TemplateSelectorScreen> {
  static const List<Map<String, dynamic>> _colorSwatches = [
    {'name': 'Indigo Blue', 'hex': 0xFF4F46E5, 'color': Color(0xFF4F46E5)},
    {'name': 'Emerald Green', 'hex': 0xFF059669, 'color': Color(0xFF059669)},
    {'name': 'Crimson Red', 'hex': 0xFFDC2626, 'color': Color(0xFFDC2626)},
    {'name': 'Amber Gold', 'hex': 0xFFD97706, 'color': Color(0xFFD97706)},
    {'name': 'Dark Slate', 'hex': 0xFF0F172A, 'color': Color(0xFF0F172A)},
    {'name': 'Royal Purple', 'hex': 0xFF7C3AED, 'color': Color(0xFF7C3AED)},
  ];

  static const List<Map<String, String>> _templates = [
    {'id': 'classic', 'title': 'Classic Corporate', 'desc': 'Standard professional layout with header bands'},
    {'id': 'modern', 'title': 'Modern Slate', 'desc': 'Card-based aesthetic with clean typography'},
    {'id': 'gst_detailed', 'title': 'GST Tax Detailed', 'desc': 'Expanded HSN/SAC & tax rate breakdown'},
    {'id': 'minimal', 'title': 'Minimal Compact', 'desc': 'Clean, lightweight design for service billing'},
  ];

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(templateConfigProvider);
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceId ?? 1));
    final businessAsync = ref.watch(businessNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice Templates & Design'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            label: const Text('Apply', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template configuration saved as default!')),
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left Controls / Drawer on larger screens, or top section
          Expanded(
            flex: 5,
            child: ListView(
              padding: AppDimensions.pagePadding,
              children: [
                // Layout Preset Selector
                _buildSectionHeader('1. Select Layout Style'),
                ..._templates.map((tpl) {
                  final isSelected = config.templateId == tpl['id'];
                  return Card(
                    color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.5) : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedMd,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                      ),
                      title: Text(tpl['title']!, style: AppTypography.labelLarge),
                      subtitle: Text(tpl['desc']!, style: AppTypography.bodySmall),
                      onTap: () {
                        ref.read(templateConfigProvider.notifier).setTemplateId(tpl['id']!);
                      },
                    ),
                  );
                }),
                const SizedBox(height: AppDimensions.lg),

                // Color Swatches
                _buildSectionHeader('2. Brand Accent Color'),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: _colorSwatches.map((item) {
                    final isSelected = config.primaryColorHex == item['hex'];
                    return InkWell(
                      onTap: () {
                        ref.read(templateConfigProvider.notifier).setPrimaryColor(item['hex'] as int);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? (item['color'] as Color) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: item['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item['name'] as String,
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected ? (item['color'] as Color) : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Element Toggles
                _buildSectionHeader('3. Displayed Fields & Sections'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Dynamic UPI QR Code', style: AppTypography.labelMedium),
                        subtitle: Text('Print scannable payment QR on invoice', style: AppTypography.bodySmall),
                        value: config.showUpiQr,
                        onChanged: (v) => ref.read(templateConfigProvider.notifier).toggleOption(showUpiQr: v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text('Bank Details', style: AppTypography.labelMedium),
                        subtitle: Text('Account number, IFSC, Branch info', style: AppTypography.bodySmall),
                        value: config.showBankDetails,
                        onChanged: (v) => ref.read(templateConfigProvider.notifier).toggleOption(showBankDetails: v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text('HSN / SAC Column', style: AppTypography.labelMedium),
                        subtitle: Text('Print tax codes in items table', style: AppTypography.bodySmall),
                        value: config.showHsnSac,
                        onChanged: (v) => ref.read(templateConfigProvider.notifier).toggleOption(showHsnSac: v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text('Authorized Signatory Block', style: AppTypography.labelMedium),
                        subtitle: Text('Include signature line for authorization', style: AppTypography.bodySmall),
                        value: config.showSignature,
                        onChanged: (v) => ref.read(templateConfigProvider.notifier).toggleOption(showSignature: v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text('Terms & Conditions', style: AppTypography.labelMedium),
                        subtitle: Text('Print standard payment conditions', style: AppTypography.bodySmall),
                        value: config.showTerms,
                        onChanged: (v) => ref.read(templateConfigProvider.notifier).toggleOption(showTerms: v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text('Payment Due Highlight Alert', style: AppTypography.labelMedium),
                        subtitle: Text('Highlight outstanding balance if unpaid', style: AppTypography.bodySmall),
                        value: config.showPaymentDueAlert,
                        onChanged: (v) => ref.read(templateConfigProvider.notifier).toggleOption(showPaymentDueAlert: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Live PDF Preview pane
          Expanded(
            flex: 6,
            child: Container(
              color: const Color(0xFF1E293B),
              child: invoiceAsync.when(
                data: (invoice) => businessAsync.when(
                  data: (business) => PdfPreview(
                    build: (format) => PdfInvoiceGenerator.generatePdf(
                      invoice: invoice,
                      business: business,
                      config: config,
                    ),
                    allowPrinting: false,
                    allowSharing: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    maxPageWidth: 600,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
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
