import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/supabase_storage_service.dart';
import '../theme/typography.dart';
import 'signature_pad_dialog.dart';

class ImageUploadCard extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String? currentUrl;
  final bool isSignature;
  final Function(String? newUrl) onImageUpdated;

  const ImageUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentUrl,
    this.isSignature = false,
    required this.onImageUpdated,
  });

  @override
  ConsumerState<ImageUploadCard> createState() => _ImageUploadCardState();
}

class _ImageUploadCardState extends ConsumerState<ImageUploadCard> {
  bool _isUploading = false;
  String? _uploadStatus;

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked != null) {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'Compressing logo (max 200KB)...';
      });

      try {
        final bytes = await picked.readAsBytes();
        final storage = ref.read(supabaseStorageServiceProvider);
        final url = await storage.uploadLogo(bytes);
        widget.onImageUpdated(url);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload logo: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadStatus = null;
          });
        }
      }
    }
  }

  Future<void> _openSignaturePad() async {
    final url = await SignaturePadDialog.show(context);
    if (url != null && mounted) {
      widget.onImageUpdated(url);
    }
  }

  Widget _buildImagePreview(String url) {
    if (url.startsWith('data:image')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 36, color: AppColors.textMuted),
        );
      } catch (_) {}
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 36, color: AppColors.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.currentUrl != null && widget.currentUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.roundedMd,
        border: Border.all(
          color: hasImage ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
          width: hasImage ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isSignature ? Icons.draw_outlined : Icons.business_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.title, style: AppTypography.headingSmall),
                ],
              ),
              if (hasImage && !_isUploading)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  tooltip: 'Remove',
                  onPressed: () async {
                    final storage = ref.read(supabaseStorageServiceProvider);
                    if (widget.isSignature) {
                      await storage.deleteSignature();
                    } else {
                      await storage.deleteLogo();
                    }
                    widget.onImageUpdated(null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.subtitle, style: AppTypography.bodySmall),
          const SizedBox(height: 12),

          if (_isUploading)
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: AppDimensions.roundedMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  const SizedBox(height: 10),
                  Text(
                    _uploadStatus ?? 'Compressing & uploading image (max 200KB)...',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            )
          else if (hasImage)
            Container(
              height: 110,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimensions.roundedMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Center(child: _buildImagePreview(widget.currentUrl!)),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: OutlinedButton.icon(
                      icon: Icon(widget.isSignature ? Icons.draw_rounded : Icons.edit_rounded, size: 14),
                      label: Text(widget.isSignature ? 'Re-sign' : 'Change', style: const TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: widget.isSignature ? _openSignaturePad : _pickAndUploadLogo,
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: widget.isSignature ? _openSignaturePad : _pickAndUploadLogo,
              borderRadius: AppDimensions.roundedMd,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: AppDimensions.roundedMd,
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isSignature ? Icons.gesture_rounded : Icons.add_photo_alternate_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isSignature ? '+ Draw / Upload Signature *' : '+ Upload Company Logo',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text('Auto compressed to ≤ 200KB', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
