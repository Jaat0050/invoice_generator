import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/typography.dart';

enum InvoiceStatusType {
  paid,
  partiallyPaid,
  unpaid,
  overdue,
  draft,
  cancelled,
}

class StatusBadge extends StatelessWidget {
  final InvoiceStatusType status;
  final String? customText;

  const StatusBadge({
    super.key,
    required this.status,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: AppDimensions.roundedFull,
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            customText ?? config.label,
            style: AppTypography.labelSmall.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(InvoiceStatusType type) {
    switch (type) {
      case InvoiceStatusType.paid:
        return const _StatusConfig(
          label: 'PAID',
          textColor: AppColors.successDark,
          backgroundColor: AppColors.successLight,
          borderColor: Color(0xFFA7F3D0),
        );
      case InvoiceStatusType.partiallyPaid:
        return const _StatusConfig(
          label: 'PARTIAL',
          textColor: AppColors.warningDark,
          backgroundColor: AppColors.warningLight,
          borderColor: Color(0xFFFDE68A),
        );
      case InvoiceStatusType.unpaid:
        return const _StatusConfig(
          label: 'UNPAID',
          textColor: Color(0xFF475569),
          backgroundColor: Color(0xFFF1F5F9),
          borderColor: Color(0xFFCBD5E1),
        );
      case InvoiceStatusType.overdue:
        return const _StatusConfig(
          label: 'OVERDUE',
          textColor: AppColors.errorDark,
          backgroundColor: AppColors.errorLight,
          borderColor: Color(0xFFFECACA),
        );
      case InvoiceStatusType.draft:
        return const _StatusConfig(
          label: 'DRAFT',
          textColor: Color(0xFF3B82F6),
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
        );
      case InvoiceStatusType.cancelled:
        return const _StatusConfig(
          label: 'CANCELLED',
          textColor: Color(0xFF64748B),
          backgroundColor: Color(0xFFF8FAFC),
          borderColor: Color(0xFFE2E8F0),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _StatusConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
