import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/unipack_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_data_provider.dart';
import '../../services/unipack_service.dart';
import '../../widgets/animated_pressable.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';

class UniPackScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const UniPackScreen({super.key, this.onNavigateTab});

  @override
  State<UniPackScreen> createState() => _UniPackScreenState();
}

class _UniPackScreenState extends State<UniPackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const AppHeader(title: 'UniPack Giá Sỉ'),
      drawer: AppDrawer(
        currentIndex: (auth.currentUser?.isOwner ?? true) ? 4 : 3,
        onTabSelected: (idx) => widget.onNavigateTab?.call(idx),
      ),
      bottomNavigationBar: data.cartCount > 0 ? _buildCartFloatingBar(context, data, auth) : null,
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(text: 'Danh mục giá sỉ'),
                Tab(text: 'Đơn đã đặt (${data.orders.length})'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(context, data),
                _buildOrdersTab(context, data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context, AppDataProvider data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ TIỆN ÍCH ĐẶC QUYỀN RENTEASY',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'UniPack - Thực phẩm giá sỉ sập sàn',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gói nhu yếu phẩm sỉ hạn dùng dài hạn độc quyền cho cư dân trọ. Rẻ hơn từ 20% - 30% so với siêu thị!',
                  style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: Color(0xFF5EEAD4)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hạn chót: Trước 22h Thứ 7 • Giao đồng loạt vào Chủ Nhật',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Weekly Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến trình gom đơn tuần này',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Đạt 75% chỉ tiêu sỉ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 8,
                    backgroundColor: AppColors.bgLight,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Danh mục sản phẩm giá sỉ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          // Products List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: UniPackService.sampleProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final prod = UniPackService.sampleProducts[index];
              return _buildProductCard(context, prod, data);
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, UniPackProduct prod, AppDataProvider data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: prod.imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.bgLight),
              errorWidget: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.primaryLight,
                child: const Icon(Icons.shopping_bag, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${prod.savePercent}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      prod.category,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  prod.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  prod.packageSize,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      Formatters.formatCurrency(prod.wholesalePrice),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.formatCurrency(prod.originalPrice),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedPressable(
                    onTap: () {
                      data.addToCart(prod);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm "${prod.name}" vào giỏ hàng!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    scaleDown: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Thêm vào giỏ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context, AppDataProvider data) {
    if (data.orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.borderLight),
            SizedBox(height: 10),
            Text('Bạn chưa có đơn đặt hàng UniPack nào', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: data.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = data.orders[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phòng: ${order.roomNumber} • Số lượng: ${order.quantity}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(order.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Chờ giao T7',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartFloatingBar(BuildContext context, AppDataProvider data, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.cartCount} sản phẩm',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  Formatters.formatCurrency(data.cartTotal),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
            const Spacer(),
            AnimatedPressable(
              onTap: () => _showCheckoutDialog(context, data, auth),
              scaleDown: 0.95,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shopping_cart_checkout_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Đặt hàng ngay',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, AppDataProvider data, AuthProvider auth) {
    final roomCtrl = TextEditingController(text: auth.tenantRoomCode ?? '101');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đặt hàng UniPack', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đơn hàng sẽ được gom và giao đồng loạt đến cửa phòng trọ vào ngày Chủ Nhật.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(labelText: 'Số phòng nhận hàng *', hintText: 'VD: 101'),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  Formatters.formatCurrency(data.cartTotal),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (roomCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await data.placeUniPackOrder(roomNumber: roomCtrl.text.trim());
              _tabController.animateTo(1);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đặt hàng UniPack thành công!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Xác nhận đặt'),
          ),
        ],
      ),
    );
  }
}
