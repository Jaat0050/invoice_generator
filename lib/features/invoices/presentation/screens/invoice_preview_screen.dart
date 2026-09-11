import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../templates/data/models/template_config_model.dart';
import '../../data/models/invoice_model.dart';
import '../../utils/pdf_invoice_generator.dart';
import 'invoice_detail_screen.dart';

class TemplateConfigNotifier extends Notifier<TemplateConfigModel> {
  @override
  TemplateConfigModel build() => const TemplateConfigModel();

  void updateConfig(TemplateConfigModel newConfig) => state = newConfig;
  void setColor(int hex) => state = state.copyWith(primaryColorHex: hex);
  void setTemplate(String id) => state = state.copyWith(templateId: id);
}

final templateConfigProvider =
    NotifierProvider<TemplateConfigNotifier, TemplateConfigModel>(TemplateConfigNotifier.new);

class InvoicePreviewScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final businessAsync = ref.watch(activeBusinessProvider);
    final templateConfig = ref.watch(templateConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Invoice Preview & PDF'),
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Customize Template',
            onPressed: () => _showTemplateCustomizerModal(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share via WhatsApp / Email',
            onPressed: () {
              if (invoiceAsync.hasValue && businessAsync.hasValue) {
                _showShareOptionsModal(context, invoiceAsync.value!, businessAsync.value!);
              }
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        data: (invoice) {
          return businessAsync.when(
            data: (business) {
              return PdfPreview(
                build: (format) => PdfInvoiceGenerator.generatePdf(
                  invoice: invoice,
                  business: business,
                  config: templateConfig,
                ),
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowPrinting: true,
                allowSharing: true,
                previewPageMargin: const EdgeInsets.all(12),
                pdfFileName: '${invoice.invoiceNumber}.pdf',
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, _) => Center(child: Text('Error loading business: $err', style: const TextStyle(color: Colors.white))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(child: Text('Error loading invoice: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  void _showTemplateCustomizerModal(BuildContext context, WidgetRef ref) {
    final colors = [
      0xFF4F46E5, // Indigo
      0xFF0EA5E9, // Sky Blue
      0xFF10B981, // Emerald Green
      0xFFE11D48, // Rose Red
      0xFF0F172A, // Slate Dark
      0xFF8B5CF6, // Purple
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final config = ref.watch(templateConfigProvider);
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  Text('Invoice Template Customizer', style: AppTypography.headingMedium),
                  const SizedBox(height: 16),
                  Text('Primary Accent Color', style: AppTypography.labelMedium),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: colors.map((colorHex) {
                      final isSelected = config.primaryColorHex == colorHex;
                      return GestureDetector(
                        onTap: () => ref.read(templateConfigProvider.notifier).setColor(colorHex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(colorHex),
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 28),
                  Text('Display Toggles', style: AppTypography.labelMedium),
                  SwitchListTile(
                    title: const Text('Show Bank & Account Details'),
                    value: config.showBankDetails,
                    onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showBankDetails: val)),
                  ),
                  SwitchListTile(
                    title: const Text('Show Instant UPI Payment QR Code'),
                    value: config.showUpiQr,
                    onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showUpiQr: val)),
                  ),
                  SwitchListTile(
                    title: const Text('Show HSN/SAC Column'),
                    value: config.showHsnSac,
                    onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showHsnSac: val)),
                  ),
                  SwitchListTile(
                    title: const Text('Show Payment Due Highlight Box'),
                    value: config.showPaymentDueAlert,
                    onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showPaymentDueAlert: val)),
                  ),
                  SwitchListTile(
                    title: const Text('Show Authorized Signature Area'),
                    value: config.showSignature,
                    onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showSignature: val)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showShareOptionsModal(BuildContext context, InvoiceModel invoice, dynamic business) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Share Invoice ${invoice.invoiceNumber}', style: AppTypography.headingMedium),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Share via WhatsApp'),
                subtitle: const Text('Send pre-filled payment message & reminder'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final msg = '''
*Invoice from ${business.name}*
Invoice No: ${invoice.invoiceNumber}
Total Amount: ${CurrencyFormatter.format(invoice.grandTotal)}
Balance Due: ${CurrencyFormatter.format(invoice.balanceDue)}
Due Date: ${DateFormatter.format(invoice.dueDate)}

Please find your tax invoice. Kindly remit the payment on or before the due date.
Thank you for your business!
''';
                  final cleanPhone = invoice.customer.phone.replaceAll(RegExp(r'\D'), '');
                  final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                  } else {
                    SharePlus.instance.share(
                      ShareParams(
                        text: msg,
                        subject: 'Invoice ${invoice.invoiceNumber} from ${business.name}',
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: AppColors.primary),
                ),
                title: const Text('Share via Email'),
                subtitle: Text('Send to ${invoice.customer.email ?? "customer email"}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final emailUrl = Uri(
                    scheme: 'mailto',
                    path: invoice.customer.email ?? '',
                    queryParameters: {
                      'subject': 'Tax Invoice ${invoice.invoiceNumber} from ${business.name}',
                      'body': 'Dear ${invoice.customer.name},\n\nPlease find attached invoice ${invoice.invoiceNumber} for ${CurrencyFormatter.format(invoice.grandTotal)}. Balance Due: ${CurrencyFormatter.format(invoice.balanceDue)}.\n\nBest Regards,\n${business.name}',
                    },
                  );
                  if (await canLaunchUrl(emailUrl)) {
                    await launchUrl(emailUrl);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
