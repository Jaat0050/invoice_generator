import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/typography.dart';

enum ButtonVariant { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == ButtonVariant.outline) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
          ),
          child: _buildChild(context, AppColors.textPrimary),
        ),
      );
    }

    if (variant == ButtonVariant.text) {
      return SizedBox(
        width: width,
        height: height,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(context, AppColors.primary),
        ),
      );
    }

    Color bgColor = AppColors.primary;
    Color fgColor = Colors.white;

    if (variant == ButtonVariant.secondary) {
      bgColor = AppColors.primaryContainer;
      fgColor = AppColors.primary;
    } else if (variant == ButtonVariant.danger) {
      bgColor = AppColors.error;
      fgColor = Colors.white;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
        ),
        child: _buildChild(context, fgColor),
      ),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: textColor),
          ),
        ],
      );
    }

    return Text(
      label,
      style: AppTypography.labelLarge.copyWith(color: textColor),
    );
  }
}
