import 'dart:async';
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
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Real-time ticker for 1-hour cancellation countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                    color: Colors.black.withValues(alpha: 0.2),
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
            separatorBuilder: (_, _) => const SizedBox(height: 14),
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
            color: Colors.black.withValues(alpha: 0.02),
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
              placeholder: (_, _) => Container(color: AppColors.bgLight),
              errorWidget: (_, _, _) => Container(
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

  // ===================== PHẦN ĐƠN HÀNG UNIPACK ĐỒNG BỘ VỚI WEB =====================
  Widget _buildOrdersTab(BuildContext context, AppDataProvider data) {
    if (data.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa đặt đơn hàng UniPack nào trong tuần này',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy ghé danh mục giá sỉ để chọn món nhu yếu phẩm yêu thích nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.storefront_rounded, size: 16),
                label: const Text('Xem danh mục giá sỉ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: data.orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = data.orders[index];
        return _buildOrderCard(context, order, data);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, UniPackOrder order, AppDataProvider data) {
    final isCancelled = order.status == 'CANCELLED';
    final canCancel = order.isCanCancel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCancelled ? AppColors.borderLight : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mã đơn + Trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF4F46E5), // Indigo
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (order.orderDate.isNotEmpty)
                      Text(
                        order.orderDate,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
                _buildStatusBadge(order),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên sản phẩm + SL + Giá
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.productName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isCancelled ? AppColors.textMuted : AppColors.textPrimary,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số lượng: x${order.quantity}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Formatters.formatCurrency(order.totalPrice),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isCancelled ? AppColors.textMuted : AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Người nhận / Phòng
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.receiverName.isNotEmpty ? order.receiverName : 'Cư dân'} • Phòng ${order.roomNumber}${order.receiverPhone.isNotEmpty ? ' - ${order.receiverPhone}' : ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Phương thức thanh toán & Trạng thái thanh toán
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Phương thức
                    Row(
                      children: [
                        if (order.paymentMethod == 'VIETQR') ...[
                          InkWell(
                            onTap: () => _showPaymentQrDialog(context, order, data),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Quét VietQR',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          const Text(
                            '💵 Tiền mặt (COD)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                          ),
                        ],
                      ],
                    ),

                    // Trạng thái thanh toán
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Text(
                          'Chưa thanh toán',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                        ),
                      )
                    else if (order.isPaid)
                      InkWell(
                        onTap: () => _confirmTogglePayment(context, order, data),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text(
                                'Đã thanh toán',
                                style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () {
                          if (order.paymentMethod == 'VIETQR') {
                            _showPaymentQrDialog(context, order, data);
                          } else {
                            _confirmTogglePayment(context, order, data);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                              SizedBox(width: 4),
                              Text(
                                'Chưa thanh toán',
                                style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // CỘT / KHỐI HẠN HỦY ĐƠN CHÍNH XÁC ĐẾN TỪNG GIÂY (1 GIỜ)
                _buildCancelDeadlineBox(order),

                const SizedBox(height: 14),

                // HÀNG THAO TÁC (Xem QR Nhận Hàng & Hủy Đơn)
                if (!isCancelled)
                  Row(
                    children: [
                      // Nút Xem QR nhận hàng
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeliveryQrDialog(context, order),
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                          label: const Text('Xem QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFFC7D2FE)),
                            backgroundColor: const Color(0xFFEEF2FF),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nút Hủy đơn (chỉ bấm được khi còn hạn 1 giờ)
                      Expanded(
                        child: canCancel
                            ? OutlinedButton.icon(
                                onPressed: () => _confirmCancelOrder(context, order, data),
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text('Hủy đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFFECACA)),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.block_rounded, size: 16, color: Color(0xFF94A3B8)),
                                label: const Text('Hết hạn hủy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF94A3B8))),
                                style: OutlinedButton.styleFrom(
                                  disabledForegroundColor: const Color(0xFF94A3B8),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  backgroundColor: const Color(0xFFF8FAFC),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Khối Hạn hủy đơn 1 giờ đếm ngược thời gian thực
  Widget _buildCancelDeadlineBox(UniPackOrder order) {
    if (order.status == 'CANCELLED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'Đơn hàng đã được hủy',
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
        ),
      );
    }

    if (order.status == 'DELIVERED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
            SizedBox(width: 6),
            Text(
              'Đơn hàng đã giao thành công',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
            ),
          ],
        ),
      );
    }

    if (order.isCanCancel) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB), // Amber-50
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)), // Amber-200
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  'Hạn hủy đơn: Còn ${order.formattedRemainingTime}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309), // Amber-700
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(
                'Đến: ${order.formattedExactDeadline}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      );
    }

    // Quá hạn 1 giờ
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_rounded, size: 14, color: Color(0xFF64748B)),
          SizedBox(width: 6),
          Text(
            'Hết hạn hủy',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          SizedBox(width: 4),
          Text(
            '(Quá thời hạn 1 giờ)',
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UniPackOrder order) {
    if (order.status == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Text(
          'Đã hủy đơn',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      );
    }

    if (order.status == 'DELIVERED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: Color(0xFF059669)),
            SizedBox(width: 3),
            Text(
              'Đã nhận hàng',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
            ),
          ],
        ),
      );
    }

    // Default: PENDING_SUNDAY_DELIVERY
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF2563EB)),
          SizedBox(width: 3),
          Text(
            'Giao Chủ Nhật',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  // Xác nhận hủy đơn hàng
  void _confirmCancelOrder(BuildContext context, UniPackOrder order, AppDataProvider data) {
    if (order.status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng này đã được hủy trước đó')),
      );
      return;
    }

    if (!order.isCanCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã quá thời hạn 1 giờ, không thể hủy đơn hàng này nữa!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xác nhận hủy đơn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn hủy đơn hàng #${order.id} (${order.productName}) không?',
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    'Thời gian hủy còn: ${order.formattedRemainingTime}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ đơn', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await data.cancelUniPackOrder(order.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Đã hủy đơn hàng #${order.id} thành công.' : 'Không thể hủy đơn (quá thời hạn 1 giờ).',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận hủy', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Đổi trạng thái thanh toán
  void _confirmTogglePayment(BuildContext context, UniPackOrder order, AppDataProvider data) {
    if (order.status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đổi trạng thái thanh toán của đơn hàng đã hủy!')),
      );
      return;
    }

    final newStatusText = order.isPaid ? 'Chưa thanh toán' : 'Đã thanh toán';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cập nhật thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Đổi trạng thái thanh toán của đơn #${order.id} thành "$newStatusText"?',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await data.toggleOrderPayment(order.id);
              messenger.showSnackBar(
                SnackBar(content: Text('Đã cập nhật: $newStatusText')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // Modal QR Nhận hàng khi shipper tới
  void _showDeliveryQrDialog(BuildContext context, UniPackOrder order) {
    final qrData = 'RENTEASY-UNIPACK-${order.id}-${order.roomNumber}';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$qrData';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    'Mã QR Nhận Hàng',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Mã đơn: #${order.id}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 16),

              // QR code
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: qrUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, _, _) => const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Thông tin giao nhận
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildDialogInfoRow('Sản phẩm:', '${order.productName} (x${order.quantity})', isBoldValue: true),
                    const SizedBox(height: 6),
                    _buildDialogInfoRow('Người nhận:', order.receiverName.isNotEmpty ? order.receiverName : 'Cư dân'),
                    const SizedBox(height: 6),
                    _buildDialogInfoRow('Vị trí giao:', 'Phòng #${order.roomNumber}', isBoldValue: true),
                    const SizedBox(height: 6),
                    _buildDialogInfoRow('Thời gian giao:', 'Chủ Nhật tuần này', valueColor: const Color(0xFF2563EB), isBoldValue: true),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Hướng dẫn
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4F46E5)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HƯỚNG DẪN: Khi shipper tới giao hàng vào Chủ Nhật, bạn xuất trình mã QR này để shipper quét xác thực nhận hàng.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF4338CA), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modal QR Chuyển khoản VietQR
  void _showPaymentQrDialog(BuildContext context, UniPackOrder order, AppDataProvider data) {
    final qrData = '247001-0901234567-MBBANK-RENTEASY-UNIPACK-${order.id}';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$qrData';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    'QR Chuyển Khoản',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Đơn hàng: #${order.id}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 16),

              // QR
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: qrUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, _, _) => const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Chi tiết chuyển khoản
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildDialogInfoRow('Ngân hàng:', 'MB Bank (Quân Đội)', isBoldValue: true),
                    const SizedBox(height: 6),
                    _buildDialogInfoRow('Số tài khoản:', '0901234567', isBoldValue: true),
                    const SizedBox(height: 6),
                    _buildDialogInfoRow('Chủ tài khoản:', 'NGUYEN VAN A', isBoldValue: true),
                    const SizedBox(height: 6),
                    _buildDialogInfoRow(
                      'Số tiền chuyển:',
                      Formatters.formatCurrency(order.totalPrice),
                      valueColor: const Color(0xFF4F46E5),
                      isBoldValue: true,
                    ),
                    const SizedBox(height: 6),
                    _buildDialogInfoRow(
                      'Nội dung chuyển:',
                      'RENTEASY UP ${order.id}',
                      valueColor: const Color(0xFFDC2626),
                      isBoldValue: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Lưu ý
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sau khi chuyển khoản thành công, hệ thống sẽ xác nhận tự động. Bạn cũng có thể click nút bên dưới để đánh dấu là Đã thanh toán.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF1D4ED8), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Nút xác nhận chuyển khoản thành công (màu xanh lá)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    if (!order.isPaid) {
                      await data.toggleOrderPayment(order.id);
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text('Đã xác nhận thanh toán thành công cho đơn #${order.id}!')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Xác nhận đã chuyển khoản thành công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildCartFloatingBar(BuildContext context, AppDataProvider data, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
    final user = auth.currentUser;
    final nameCtrl = TextEditingController(text: user?.fullName.isNotEmpty == true ? user!.fullName : 'Cư dân');
    final phoneCtrl = TextEditingController(
      text: (user?.phone != null && user!.phone!.isNotEmpty) ? user.phone! : '0901234567',
    );
    final roomCtrl = TextEditingController(text: auth.tenantRoomCode ?? '101');
    String selectedPaymentMethod = 'COD'; // 'COD' | 'VIETQR'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            actionsPadding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            title: const Row(
              children: [
                Icon(Icons.shopping_cart_checkout_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Xác nhận đặt hàng UniPack',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đơn hàng sẽ được gom và giao đồng loạt đến tận cửa phòng trọ của bạn vào ngày Chủ Nhật.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  // Tên người nhận
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tên người nhận *',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // SĐT
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại nhận hàng *',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Số phòng
                  TextField(
                    controller: roomCtrl,
                    decoration: InputDecoration(
                      labelText: 'Số phòng nhận hàng *',
                      hintText: 'VD: 101',
                      prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hình thức thanh toán
                  const Text(
                    'Hình thức thanh toán:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedPaymentMethod = 'COD'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 'COD' ? const Color(0xFFEEF2FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedPaymentMethod == 'COD' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                width: selectedPaymentMethod == 'COD' ? 1.8 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '💵 Tiền mặt (COD)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: selectedPaymentMethod == 'COD' ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedPaymentMethod = 'VIETQR'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 'VIETQR' ? const Color(0xFFEEF2FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedPaymentMethod == 'VIETQR' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                width: selectedPaymentMethod == 'VIETQR' ? 1.8 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '🏦 Chuyển VietQR',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: selectedPaymentMethod == 'VIETQR' ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Lưu ý giao hàng
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCE8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFEF08A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFCA8A04)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Hàng được giao đồng loạt vào Chủ Nhật tuần này trước phòng trọ của bạn.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF854D0E), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tổng tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      Text(
                        Formatters.formatCurrency(data.cartTotal),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 17),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (roomCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập số phòng nhận hàng')),
                    );
                    return;
                  }
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đầy đủ tên và số điện thoại')),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  await data.placeUniPackOrder(
                    roomNumber: roomCtrl.text.trim(),
                    receiverName: nameCtrl.text.trim(),
                    receiverPhone: phoneCtrl.text.trim(),
                    paymentMethod: selectedPaymentMethod,
                  );
                  _tabController.animateTo(1);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Đặt hàng UniPack thành công! Bạn có 1 giờ để hủy đơn nếu đổi ý.'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text('Xác nhận đặt hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
