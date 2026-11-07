import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../templates/presentation/providers/template_config_provider.dart';
import '../../data/models/invoice_model.dart';
import '../../utils/pdf_invoice_generator.dart';
import 'invoice_detail_screen.dart';
import 'invoice_list_screen.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final int invoiceId;

  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  double _currentScale = 1.0;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward(from: 0);
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.35).clamp(0.6, 4.5);
    final currentTranslation = _transformationController.value.getTranslation();
    final matrix = Matrix4.identity()
      ..translate(currentTranslation.x * 1.35, currentTranslation.y * 1.35)
      ..scale(newScale);
    _animateToMatrix(matrix);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.35).clamp(0.6, 4.5);
    if (newScale <= 1.05) {
      _resetZoom();
      return;
    }
    final currentTranslation = _transformationController.value.getTranslation();
    final matrix = Matrix4.identity()
      ..translate(currentTranslation.x / 1.35, currentTranslation.y / 1.35)
      ..scale(newScale);
    _animateToMatrix(matrix);
  }

  void _resetZoom() {
    _animateToMatrix(Matrix4.identity());
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.15) {
      _resetZoom();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const targetScale = 2.0;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      final zoomedMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(targetScale);
      _animateToMatrix(zoomedMatrix);
    }
  }

  void _handleBack() {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(invoiceListProvider);
    ref.invalidate(activeBusinessProvider);
    ref.invalidate(businessNotifierProvider);

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  Widget _buildFloatingZoomControls() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xE61E293B), // Slate 800 (90% opacity)
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom Out Button
              IconButton(
                icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                tooltip: 'Zoom Out',
                splashRadius: 20,
                onPressed: _zoomOut,
              ),
              // Percentage Badge (Tap to Reset)
              InkWell(
                onTap: _resetZoom,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${(_currentScale * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Zoom In Button
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                tooltip: 'Zoom In',
                splashRadius: 20,
                onPressed: _zoomIn,
              ),
              Container(
                height: 20,
                width: 1,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // Fit / Reset Zoom Button
              IconButton(
                icon: const Icon(Icons.fit_screen_rounded, color: Colors.white, size: 20),
                tooltip: 'Fit to Screen (Reset)',
                splashRadius: 20,
                onPressed: _resetZoom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));
    final businessAsync = ref.watch(activeBusinessProvider);
    final templateConfig = ref.watch(templateConfigProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _handleBack),
          title: const Text('Invoice Preview & PDF', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.tune_rounded, color: Colors.white), tooltip: 'Customize Template', onPressed: () => _showTemplateCustomizerModal(context, ref)),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
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
                return Stack(
                  children: [
                    GestureDetector(
                      onDoubleTapDown: (details) => _doubleTapDetails = details,
                      onDoubleTap: _handleDoubleTap,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.6,
                        maxScale: 4.5,
                        boundaryMargin: const EdgeInsets.symmetric(horizontal: 80, vertical: 120),
                        child: PdfPreview(
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
                        ),
                      ),
                    ),
                    _buildFloatingZoomControls(),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (err, _) => Center(child: Text('Error loading business: $err', style: const TextStyle(color: Colors.white))),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, _) => Center(child: Text('Error loading invoice: $err', style: const TextStyle(color: Colors.white))),
        ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    children:
                        colors.map((colorHex) {
                          final isSelected = config.primaryColorHex == colorHex;
                          return GestureDetector(onTap: () => ref.read(templateConfigProvider.notifier).setColor(colorHex), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(colorHex), shape: BoxShape.circle, border: isSelected ? Border.all(color: Colors.black, width: 3) : null), child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null));
                        }).toList(),
                  ),
                  const Divider(height: 28),
                  Text('Display Toggles', style: AppTypography.labelMedium),
                  SwitchListTile(title: const Text('Show Company Logo'), value: config.showLogo, onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showLogo: val))),
                  SwitchListTile(title: const Text('Show Supply & Document Details'), subtitle: const Text('Place of supply, tax mode & details'), value: config.showSupplyDetails, onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showSupplyDetails: val))),
                  SwitchListTile(title: const Text('Show Bank & UPI Transfer Details'), subtitle: const Text('Bank A/C, IFSC, branch & UPI transfer info'), value: config.showBankDetails, onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showBankDetails: val))),
                  SwitchListTile(title: const Text('Show Instant UPI Payment QR Code'), subtitle: const Text('Print scannable payment QR code'), value: config.showUpiQr, onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showUpiQr: val))),
                  SwitchListTile(title: const Text('Show HSN/SAC Column'), value: config.showHsnSac, onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showHsnSac: val))),
                  SwitchListTile(title: const Text('Show Payment Due Highlight Box'), value: config.showPaymentDueAlert, onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showPaymentDueAlert: val))),
                  SwitchListTile(title: const Text('Show Authorized Signature Area'), value: config.showSignature, onChanged: (val) => ref.read(templateConfigProvider.notifier).updateConfig(config.copyWith(showSignature: val))),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                leading: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A))),
                title: const Text('Share via WhatsApp'),
                subtitle: const Text('Send pre-filled payment message & reminder'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final dueInfo = invoice.dueDate != null ? 'Due Date: ${DateFormatter.format(invoice.dueDate)}\n' : '';
                  final msg = '''
*Invoice from ${business.name}*
Invoice No: ${invoice.invoiceNumber}
Total Amount: ${CurrencyFormatter.format(invoice.grandTotal)}
Balance Due: ${CurrencyFormatter.format(invoice.balanceDue)}
$dueInfo
Please find your invoice. Kindly remit the payment${invoice.dueDate != null ? " on or before the due date" : ""}.
Thank you for your business!
''';
                  final cleanPhone = invoice.customer.phone.replaceAll(RegExp(r'\D'), '');
                  final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                  } else {
                    SharePlus.instance.share(ShareParams(text: msg, subject: 'Invoice ${invoice.invoiceNumber} from ${business.name}'));
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle), child: const Icon(Icons.email_outlined, color: AppColors.primary)),
                title: const Text('Share via Email'),
                subtitle: Text('Send to ${invoice.customer.email ?? "customer email"}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final emailUrl = Uri(
                    scheme: 'mailto',
                    path: invoice.customer.email ?? '',
                    queryParameters: {'subject': '${invoice.invoiceTitle} ${invoice.invoiceNumber} from ${business.name}', 'body': 'Dear ${invoice.customer.name},\n\nPlease find attached invoice ${invoice.invoiceNumber} for ${CurrencyFormatter.format(invoice.grandTotal)}. Balance Due: ${CurrencyFormatter.format(invoice.balanceDue)}.\n\nBest Regards,\n${business.name}'},
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
