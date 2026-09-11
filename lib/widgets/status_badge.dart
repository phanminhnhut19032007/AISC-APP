import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });

  factory StatusBadge.room(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return const StatusBadge(
          label: 'Còn trống',
          textColor: AppColors.success,
          backgroundColor: AppColors.successBg,
        );
      case 'RENTED':
      case 'OCCUPIED':
        return const StatusBadge(
          label: 'Đang thuê',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight,
        );
      case 'MAINTENANCE':
        return const StatusBadge(
          label: 'Bảo trì',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningBg,
        );
      default:
        return StatusBadge(
          label: status,
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.bgLight,
        );
    }
  }

  factory StatusBadge.invoice(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const StatusBadge(
          label: 'Đã thanh toán',
          textColor: AppColors.success,
          backgroundColor: AppColors.successBg,
          icon: Icons.check_circle_rounded,
        );
      case 'SENT':
      case 'DRAFT':
      case 'PENDING':
        return const StatusBadge(
          label: 'Chờ thanh toán',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningBg,
          icon: Icons.access_time_rounded,
        );
      case 'OVERDUE':
        return const StatusBadge(
          label: 'Quá hạn',
          textColor: AppColors.danger,
          backgroundColor: AppColors.dangerBg,
          icon: Icons.error_outline_rounded,
        );
      default:
        return StatusBadge(
          label: status,
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.bgLight,
        );
    }
  }

  factory StatusBadge.ticket(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const StatusBadge(
          label: 'Chờ tiếp nhận',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningBg,
          icon: Icons.pending_outlined,
        );
      case 'ASSIGNED':
        return const StatusBadge(
          label: 'Đã tiếp nhận',
          textColor: AppColors.info,
          backgroundColor: AppColors.infoBg,
          icon: Icons.person_pin_outlined,
        );
      case 'IN_PROGRESS':
        return const StatusBadge(
          label: 'Đang sửa chữa',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight,
          icon: Icons.construction_rounded,
        );
      case 'CLOSED':
      case 'RESOLVED':
        return const StatusBadge(
          label: 'Đã giải quyết',
          textColor: AppColors.success,
          backgroundColor: AppColors.successBg,
          icon: Icons.check_circle_rounded,
        );
      default:
        return StatusBadge(
          label: status,
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.bgLight,
        );
    }
  }

  factory StatusBadge.priority(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return const StatusBadge(
          label: 'Khẩn cấp',
          textColor: AppColors.danger,
          backgroundColor: AppColors.dangerBg,
        );
      case 'HIGH':
        return const StatusBadge(
          label: 'Cao',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningBg,
        );
      case 'MEDIUM':
        return const StatusBadge(
          label: 'Trung bình',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight,
        );
      case 'LOW':
        return const StatusBadge(
          label: 'Thấp',
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.bgLight,
        );
      default:
        return StatusBadge(
          label: priority,
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.bgLight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
