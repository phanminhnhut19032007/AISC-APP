import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/animated_pressable.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<AppDataProvider>().refreshAll(
            auth.currentUser,
            roomCode: auth.tenantRoomCode,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final user = auth.currentUser;
    final isOwner = user?.isOwner ?? true;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppHeader(title: isOwner ? 'Tổng quan' : 'Tổng quan cư dân'),
      drawer: AppDrawer(
        currentIndex: 0,
        onTabSelected: (idx) => widget.onNavigateTab?.call(idx),
      ),
      body: RefreshIndicator(
        onRefresh: () => data.refreshAll(user, roomCode: auth.tenantRoomCode),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOwner)
                _buildOwnerDashboard(context, data)
              else
                _buildTenantDashboard(context, data, auth),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TENANT DASHBOARD (Pixel-perfect to Web)
  // ==========================================
  Widget _buildTenantDashboard(BuildContext context, AppDataProvider data, AuthProvider auth) {
    final roomCode = auth.tenantRoomCode ?? '101';
    final building = data.selectedBuilding;
    final latestInvoice = data.invoices.isNotEmpty ? data.invoices.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Blue Welcome Hero Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, Phòng $roomCode!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chào mừng bạn đến với REASY. Tất cả thông tin thuê phòng, hóa đơn và sự cố được cập nhật liên tục tại đây.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFE2E8F0),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.home_outlined, size: 28, color: Colors.white),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Current Month Invoice Card
        if (latestInvoice != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hóa đơn phòng tháng ${latestInvoice.month}/${latestInvoice.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phòng #$roomCode - ${building?.name ?? "Nha Tro Minh Chau"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.invoice(latestInvoice.status),
                  ],
                ),

                const SizedBox(height: 16),

                // Invoice Breakdown & Status Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      _buildInvoiceRow('Tiền phòng cơ bản:', Formatters.formatCurrency(latestInvoice.baseRent)),
                      const SizedBox(height: 8),
                      _buildInvoiceRow('Tiền điện:', Formatters.formatCurrency(latestInvoice.electricityAmount)),
                      const SizedBox(height: 8),
                      _buildInvoiceRow('Tiền nước:', Formatters.formatCurrency(latestInvoice.waterAmount)),
                      const Divider(height: 18, color: AppColors.borderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng tiền thanh toán:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            Formatters.formatCurrency(latestInvoice.totalAmount),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Payment Status Banner Box
                if (latestInvoice.isPaid)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hóa đơn đã được thanh toán',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cảm ơn bạn đã đóng tiền phòng đầy đủ!',
                              style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  AnimatedPressable(
                    onTap: () => widget.onNavigateTab?.call(1),
                    scaleDown: 0.96,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Quét mã QR để thanh toán ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 3. Information & Tickets Row (Thông tin phòng thuê & Sự cố bạn đã báo)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'THÔNG TIN PHÒNG THUÊ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'SỐ PHÒNG TRỌ:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                'Phòng $roomCode',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 8),
              Text(
                'TÒA NHÀ:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                building?.name ?? 'Nha Tro Minh Chau',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'ĐỊA CHỈ CỤ THỂ:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                building?.address ?? '45 Duong D1, P. Binh Thanh, TP.HCM',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 4. Sự cố bạn đã báo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.handyman_rounded, color: Color(0xFFF97316), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'SỰ CỐ BẠN ĐÃ BÁO',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => widget.onNavigateTab?.call(2),
                    child: const Text(
                      'Gửi báo cáo +',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.tickets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Bạn chưa gửi yêu cầu sự cố nào', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.tickets.take(3).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final t = data.tickets[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (t.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    t.description,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.ticket(t.status),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 5. Lịch sử hóa đơn phòng Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử hóa đơn phòng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigateTab?.call(1),
                      child: const Text(
                        'Sắp xếp gần nhất',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              if (data.invoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text('Chưa có lịch sử hóa đơn nào', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 34,
                    ),
                    child: DataTable(
                      horizontalMargin: 16,
                      columnSpacing: 18,
                      headingRowHeight: 40,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 56,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'THÁNG/NĂM',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'TỔNG TIỀN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'TRẠNG THÁI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'NGÀY THANH TOÁN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'CHI TIẾT QR',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                      rows: data.invoices.take(6).map((inv) {
                        final dateStr = inv.paidAt != null
                            ? Formatters.formatDate(inv.paidAt!)
                            : (inv.dueDate != null ? Formatters.formatDate(inv.dueDate!) : '27/8/2026');

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                'Tháng ${inv.month}/${inv.year}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                            DataCell(
                              Text(
                                Formatters.formatCurrency(inv.totalAmount),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ),
                            DataCell(
                              StatusBadge.invoice(inv.status),
                            ),
                            DataCell(
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF2563EB)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => widget.onNavigateTab?.call(1),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  // ==========================================
  // OWNER DASHBOARD
  // ==========================================
  Widget _buildOwnerDashboard(BuildContext context, AppDataProvider data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            KpiCard(
              title: 'Tổng số phòng',
              value: '${data.totalRooms}',
              subtitle: '${data.buildings.length} tòa nhà',
              icon: Icons.apartment_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF2563EB),
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            KpiCard(
              title: 'Đang thuê',
              value: '${data.rentedRooms}',
              subtitle: '${data.availableRooms} phòng trống',
              icon: Icons.door_front_door_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF10B981),
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            KpiCard(
              title: 'Doanh thu tháng này',
              value: Formatters.formatCurrency(data.monthlyRevenue),
              subtitle: '${data.invoices.length} hóa đơn',
              icon: Icons.trending_up_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF8B5CF6),
              onTap: () => widget.onNavigateTab?.call(2),
            ),
            KpiCard(
              title: 'Phiếu bảo trì cần xử lý',
              value: '${data.openTicketsCount}',
              subtitle: '${data.openTicketsCount} yêu cầu chưa đóng',
              icon: Icons.build_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFFF97316),
              onTap: () => widget.onNavigateTab?.call(3),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: AnimatedPressable(
                onTap: () => widget.onNavigateTab?.call(2),
                scaleDown: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Quản lý hóa đơn',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedPressable(
                onTap: () => widget.onNavigateTab?.call(3),
                scaleDown: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handyman_outlined, color: AppColors.textPrimary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Xử lý bảo trì',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent Invoices Table Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hóa đơn gần đây',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigateTab?.call(2),
                      child: const Row(
                        children: [
                          Text(
                            'Xem tất cả',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.north_east_rounded, size: 14, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              if (data.invoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Chưa có dữ liệu hóa đơn', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 34),
                    child: DataTable(
                      horizontalMargin: 16,
                      columnSpacing: 20,
                      headingRowHeight: 40,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 56,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'MÃ PHÒNG',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'THÁNG',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'TỔNG TIỀN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'TRẠNG THÁI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'NGÀY',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                      rows: data.invoices.take(6).map((inv) {
                        final roomIdDisplay =
                            inv.roomId.length > 8 ? '${inv.roomId.substring(0, 8)}...' : inv.roomId;

                        return DataRow(
                          cells: [
                            DataCell(Text(roomIdDisplay, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            DataCell(Text('T${inv.month}/${inv.year}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                            DataCell(Text(Formatters.formatCurrency(inv.totalAmount), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800))),
                            DataCell(StatusBadge.invoice(inv.status)),
                            DataCell(
                              Text(
                                inv.paidAt != null
                                    ? Formatters.formatDate(inv.paidAt!)
                                    : (inv.dueDate != null ? Formatters.formatDate(inv.dueDate!) : '26/8/2026'),
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
