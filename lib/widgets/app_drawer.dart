import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/app_data_provider.dart';
import 'animated_pressable.dart';
import 'siren_icon.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final user = auth.currentUser;
    final isOwner = user?.isOwner ?? true;

    return Drawer(
      backgroundColor: const Color(0xFF0B132B), // Exact dark navy from web sidebar
      child: SafeArea(
        child: Column(
          children: [
            // Header: Brand Logo & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          'REASY',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REASY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOwner ? 'Bảng điều khiển Admin' : 'Cư dân REASY',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 12),

            // Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: isOwner
                    ? [
                        _buildDrawerItem(
                          icon: Icons.grid_view_rounded,
                          title: 'Tổng quan',
                          index: 0,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.apartment_rounded,
                          title: 'Tòa nhà',
                          index: 1,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.description_outlined,
                          title: 'Hóa đơn phòng',
                          index: 2,
                          badgeCount: data.pendingInvoicesCount,
                          badgeColor: AppColors.warning,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.handyman_rounded,
                          title: 'Bảo trì & Sửa chữa',
                          index: 3,
                          badgeCount: data.openTicketsCount,
                          badgeColor: AppColors.danger,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Tiện ích UniPack',
                          index: 4,
                          badgeCount: data.cartCount,
                          badgeColor: AppColors.success,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Chat',
                          index: 5,
                          context: context,
                        ),
                        _buildDrawerItem(
                          customIconBuilder: (color) => SirenIcon(color: color, size: 20),
                          title: 'Tin Khẩn Cấp',
                          index: 6,
                          isDangerRed: true,
                          badgeCount: data.unreadEmergencyCount,
                          badgeColor: const Color(0xFFEF4444),
                          context: context,
                        ),
                      ]
                    : [
                        _buildDrawerItem(
                          icon: Icons.grid_view_rounded,
                          title: 'Tổng quan',
                          index: 0,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.description_outlined,
                          title: 'Hóa đơn phòng',
                          index: 1,
                          badgeCount: data.pendingInvoicesCount,
                          badgeColor: AppColors.warning,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.handyman_rounded,
                          title: 'Báo cáo sự cố',
                          index: 2,
                          badgeCount: data.openTicketsCount,
                          badgeColor: AppColors.danger,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Tiện ích UniPack',
                          index: 3,
                          badgeCount: data.cartCount,
                          badgeColor: AppColors.success,
                          context: context,
                        ),
                        _buildDrawerItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Chat',
                          index: 4,
                          context: context,
                        ),
                        _buildDrawerItem(
                          customIconBuilder: (color) => SirenIcon(color: color, size: 20),
                          title: 'Báo Khẩn Cấp',
                          index: 5,
                          isDangerRed: true,
                          context: context,
                        ),
                      ],
              ),
            ),

            // Footer: User & Logout
            const Divider(color: Color(0xFF1E293B), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedPressable(
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  _showLogoutConfirmation(context, auth);
                },
                scaleDown: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    IconData? icon,
    Widget Function(Color color)? customIconBuilder,
    required String title,
    required int index,
    required BuildContext context,
    int? badgeCount,
    Color? badgeColor,
    bool isDangerRed = false,
  }) {
    final isSelected = currentIndex == index;

    Color bg;
    Color fg;
    BoxBorder? border;
    List<BoxShadow>? shadows;

    if (isDangerRed) {
      if (isSelected) {
        bg = const Color(0xFFDC2626); // Filled solid red when active/selected
        fg = Colors.white;
        shadows = [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
      } else {
        bg = Colors.transparent; // Transparent with red outline when inactive
        fg = const Color(0xFFEF4444); // Red text & icon
        border = Border.all(color: const Color(0xFFDC2626), width: 1.5); // Red border
      }
    } else {
      bg = isSelected ? const Color(0xFF2563EB) : Colors.transparent;
      fg = isSelected ? Colors.white : const Color(0xFF94A3B8);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedPressable(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context); // close drawer
          onTabSelected(index);
        },
        scaleDown: 0.97,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: border,
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              customIconBuilder != null
                  ? customIconBuilder(fg)
                  : Icon(
                      icon ?? Icons.circle,
                      color: fg,
                      size: 20,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: (isSelected || isDangerRed) ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppDataProvider>().reset();
              auth.logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
