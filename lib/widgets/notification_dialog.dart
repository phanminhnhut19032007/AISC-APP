import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/notification_model.dart';
import '../providers/app_data_provider.dart';

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 420),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Consumer<AppDataProvider>(
                    builder: (context, data, _) {
                      if (data.notifications.isEmpty) return const SizedBox.shrink();
                      return TextButton.icon(
                        onPressed: () => data.markAllNotificationsAsRead(),
                        icon: const Icon(Icons.done_all, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Đọc hết',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Notification List
            Expanded(
              child: Consumer<AppDataProvider>(
                builder: (context, data, _) {
                  final notifs = data.notifications;
                  if (notifs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.borderLight),
                          SizedBox(height: 8),
                          Text(
                            'Không có thông báo nào',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final item = notifs[index];
                      return _buildNotificationItem(context, item, data);
                    },
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: const Center(
                child: Text(
                  'HỆ THỐNG THÔNG BÁO RENTEASY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotificationModel item, AppDataProvider data) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (item.type) {
      case 'TICKET':
        icon = Icons.build_rounded;
        iconColor = AppColors.warning;
        iconBg = AppColors.warningBg;
        break;
      case 'INVOICE':
        icon = Icons.receipt_long_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primaryLight;
        break;
      case 'ORDER':
        icon = Icons.shopping_bag_rounded;
        iconColor = AppColors.success;
        iconBg = AppColors.successBg;
        break;
      case 'CHAT':
        icon = Icons.chat_bubble_rounded;
        iconColor = AppColors.info;
        iconBg = AppColors.infoBg;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppColors.textSecondary;
        iconBg = AppColors.bgLight;
    }

    return InkWell(
      onTap: () {
        data.markNotificationAsRead(item.id);
        Navigator.pop(context);
      },
      child: Container(
        color: item.isRead ? Colors.white : AppColors.primaryLight.withOpacity(0.4),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.formatTimeAgo(item.createdAt),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
