import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/supabase_storage_service.dart';
import '../theme/typography.dart';
import 'app_button.dart';

class SignaturePadDialog extends ConsumerStatefulWidget {
  final Function(String signatureUrl)? onSignatureSaved;

  const SignaturePadDialog({super.key, this.onSignatureSaved});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SignaturePadDialog(),
    );
  }

  @override
  ConsumerState<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends ConsumerState<SignaturePadDialog> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _strokeColor = const Color(0xFF0F172A); // Slate Dark
  bool _isUploading = false;
  String? _statusText;

  final List<Color> _penColors = const [
    Color(0xFF0F172A), // Dark Slate / Black
    Color(0xFF1E3A8A), // Navy Blue
    Color(0xFF047857), // Forest Green
  ];

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      await _uploadBytes(bytes);
    }
  }

  Future<Uint8List?> _captureCanvasBytes() async {
    try {
      final boundary = _signatureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing signature canvas: $e');
      return null;
    }
  }

  Future<void> _saveDrawnSignature() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature first or upload an image.')),
      );
      return;
    }

    final bytes = await _captureCanvasBytes();
    if (bytes != null) {
      await _uploadBytes(bytes);
    }
  }

  Future<void> _uploadBytes(Uint8List bytes) async {
    setState(() {
      _isUploading = true;
      _statusText = 'Compressing & uploading signature (max 200KB)...';
    });

    try {
      final storage = ref.read(supabaseStorageServiceProvider);
      final url = await storage.uploadSignature(bytes);

      if (mounted) {
        if (widget.onSignatureSaved != null) {
          widget.onSignatureSaved!(url);
        }
        Navigator.pop(context, url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload signature: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Authorized Signature', style: AppTypography.headingMedium),
                  const SizedBox(height: 2),
                  Text('Draw your signature or upload from gallery', style: AppTypography.bodySmall),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tools: Color picker, Undo, Clear, Gallery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Colors
              Row(
                children: _penColors.map((c) {
                  final isSelected = _strokeColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _strokeColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppColors.primary, width: 2.5) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),

              // Actions
              Row(
                children: [
                  IconButton(
                    tooltip: 'Undo last stroke',
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    onPressed: _strokes.isNotEmpty
                        ? () {
                            setState(() {
                              _strokes.removeLast();
                            });
                          }
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Clear canvas',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: _strokes.isNotEmpty
                        ? () {
                            setState(() {
                              _strokes.clear();
                              _currentStroke.clear();
                            });
                          }
                        : null,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Upload', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: _isUploading ? null : _pickFromGallery,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Signature Canvas Area
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDimensions.roundedMd,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: AppDimensions.roundedMd,
              child: Stack(
                children: [
                  // Baseline reference line
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 35,
                    child: Container(height: 1, color: Colors.grey.shade300),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 12,
                    child: Text(
                      'Sign above line',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                    ),
                  ),
                  // Interactive Canvas inside RepaintBoundary
                  RepaintBoundary(
                    key: _signatureKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        setState(() {
                          _currentStroke = [details.localPosition];
                          _strokes.add(_currentStroke);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentStroke.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _currentStroke = [];
                        });
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          color: _strokeColor,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_statusText != null) ...[
            Center(
              child: Text(
                _statusText!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Save Button
          AppButton(
            label: 'Save & Apply Signature',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isUploading,
            onPressed: _saveDrawnSignature,
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;

  _SignaturePainter({required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }

      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);

      for (int i = 0; i < stroke.length - 1; i++) {
        final p0 = stroke[i];
        final p1 = stroke[i + 1];
        // Smooth quadratic bezier curve
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
