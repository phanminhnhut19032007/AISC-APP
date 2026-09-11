import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/animated_pressable.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_badge.dart';

class InvoicesScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const InvoicesScreen({super.key, this.onNavigateTab});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _statusFilter = 'ALL'; // ALL, SENT, PAID, OVERDUE

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final isOwner = auth.currentUser?.isOwner ?? true;

    // Filter invoices
    var filteredInvoices = data.invoices;
    if (_statusFilter == 'PAID') {
      filteredInvoices = filteredInvoices.where((i) => i.isPaid).toList();
    } else if (_statusFilter == 'SENT') {
      filteredInvoices = filteredInvoices.where((i) => i.isPending).toList();
    } else if (_statusFilter == 'OVERDUE') {
      filteredInvoices = filteredInvoices.where((i) => i.isOverdue).toList();
    }

    final totalPaid = data.invoices.where((i) => i.isPaid).fold(0.0, (sum, i) => sum + i.totalAmount);
    final totalPending = data.invoices.where((i) => !i.isPaid).fold(0.0, (sum, i) => sum + i.totalAmount);
    final paidCount = data.invoices.where((i) => i.isPaid).length;
    final pendingCount = data.invoices.where((i) => !i.isPaid).length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const AppHeader(title: 'Hóa đơn phòng trọ'),
      drawer: AppDrawer(
        currentIndex: isOwner ? 2 : 1,
        onTabSelected: (idx) => widget.onNavigateTab?.call(idx),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showGenerateInvoiceDialog(context, data),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
              label: const Text(
                'Lập hóa đơn',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => data.fetchInvoices(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top 3 Summary Cards matching Web UI (Cần thanh toán / Lịch sử / Phòng đang thuê)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Card 1: Cần thanh toán
                    Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5), // Mint Green background
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CẦN THANH TOÁN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF047857),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Formatters.formatCurrency(totalPending),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF065F46),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalPending == 0 ? '✅ Đã hoàn tất đóng tiền phòng' : '⚠️ Còn $pendingCount hóa đơn cần đóng',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 2: Lịch sử đã đóng
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'LỊCH SỬ ĐÃ ĐÓNG',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Formatters.formatCurrency(totalPaid),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$paidCount kỳ hóa đơn đã hoàn tất đóng',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 3: Phòng đang thuê
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PHÒNG ĐANG THUÊ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.apartment_rounded, color: Color(0xFF4F46E5), size: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${auth.tenantRoomCode ?? "101"}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2563EB),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.selectedBuilding?.name ?? 'Nhà Trọ Minh Châu',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
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

              const SizedBox(height: 18),

              // Owner Mode Toggle (Hoạt động / Thùng rác)
              if (isOwner) ...[
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Hoạt động'),
                      selected: !data.showDeletedInvoices,
                      onSelected: (_) => data.setShowDeletedInvoices(false),
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !data.showDeletedInvoices ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: !data.showDeletedInvoices ? const Color(0xFF2563EB) : AppColors.borderLight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🗑️ Thùng rác'),
                      selected: data.showDeletedInvoices,
                      onSelected: (_) => data.setShowDeletedInvoices(true),
                      selectedColor: const Color(0xFFDC2626),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: data.showDeletedInvoices ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: data.showDeletedInvoices ? const Color(0xFFDC2626) : AppColors.borderLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Filter Bar & Refresh Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Tất cả', 'ALL'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Chờ thanh toán', 'SENT'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Đã thanh toán', 'PAID'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Quá hạn', 'OVERDUE'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reload Button
                  AnimatedPressable(
                    onTap: () => data.fetchInvoices(),
                    scaleDown: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 15, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text(
                            'Tải lại',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Invoices Table Container Card
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
                    // Group Header Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text(
                            'Danh sách hóa đơn phòng (${filteredInvoices.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppColors.borderLight),

                    if (filteredInvoices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_rounded, size: 44, color: AppColors.borderLight),
                              SizedBox(height: 8),
                              Text(
                                'Không có hóa đơn nào phù hợp',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
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
                            headingRowHeight: 42,
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 62,
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'KỲ HÓA ĐƠN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'TIỀN PHÒNG',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'TIỀN ĐIỆN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'TIỀN NƯỚC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'TỔNG TIỀN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'TRẠNG THÁI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'THANH TOÁN & LỊCH SỬ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            rows: filteredInvoices.map((inv) {
                              final isPaid = inv.isPaid;
                              final dateDisplay = inv.paidAt != null
                                  ? Formatters.formatDate(inv.paidAt!)
                                  : (inv.dueDate != null ? Formatters.formatDate(inv.dueDate!) : '27/8/2026');

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      'Tháng ${inv.month}/${inv.year}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Formatters.formatCurrency(inv.baseRent),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Formatters.formatCurrency(inv.electricityAmount),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Formatters.formatCurrency(inv.waterAmount),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Formatters.formatCurrency(inv.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    StatusBadge.invoice(inv.status),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (data.showDeletedInvoices) ...[
                                          // Nút Khôi phục trong thùng rác
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await data.restoreInvoice(inv.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Đã khôi phục hóa đơn thành công!')),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.restore_from_trash_rounded, size: 14),
                                            label: const Text('Khôi phục', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF059669),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              elevation: 0,
                                            ),
                                          ),
                                        ] else if (isPaid) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_rounded, size: 12, color: Color(0xFF059669)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  dateDisplay,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // QR Button
                                          AnimatedPressable(
                                            onTap: () => _showVietQRDialog(context, inv),
                                            scaleDown: 0.92,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.bgLight,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.borderLight),
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_2_rounded,
                                                size: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          // Chưa thanh toán
                                          if (isOwner) ...[
                                            // Nút Thu tiền mặt (Chủ trọ)
                                            AnimatedPressable(
                                              onTap: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: const Text('Xác nhận thu tiền mặt'),
                                                    content: Text('Xác nhận đã nhận đủ ${Formatters.formatCurrency(inv.totalAmount)} tiền mặt cho hóa đơn này?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xác nhận')),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await data.markInvoicePaid(inv.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Đã cập nhật trạng thái thu tiền mặt!')),
                                                    );
                                                  }
                                                }
                                              },
                                              scaleDown: 0.94,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.payments_outlined, size: 13, color: Color(0xFF059669)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Thu tiền mặt',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF059669),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Nút Xóa (cho vào thùng rác)
                                            IconButton(
                                              onPressed: () => _confirmDeleteInvoice(context, inv, data),
                                              icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'Xóa tạm thời',
                                            ),
                                            const SizedBox(width: 6),
                                          ] else ...[
                                            AnimatedPressable(
                                              onTap: () => _showVietQRDialog(context, inv),
                                              scaleDown: 0.94,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2563EB),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.qr_code_rounded, size: 13, color: Colors.white),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Thanh toán',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          // QR Button
                                          AnimatedPressable(
                                            onTap: () => _showVietQRDialog(context, inv),
                                            scaleDown: 0.92,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.bgLight,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.borderLight),
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_2_rounded,
                                                size: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : AppColors.borderLight),
      ),
    );
  }

  void _showVietQRDialog(BuildContext context, InvoiceModel inv) {
    final qrUrl = inv.vietqrCode ??
        'https://img.vietqr.io/image/MB-0000000000-compact2.jpg?amount=${inv.totalAmount.toInt()}&addInfo=${inv.paymentReference ?? "SR"}&accountName=CHU%20TRO';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quét mã VietQR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: CachedNetworkImage(
                  imageUrl: qrUrl,
                  height: 240,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(
                    height: 240,
                    child: Center(child: Icon(Icons.error_outline, size: 40, color: AppColors.danger)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số tiền:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          Formatters.formatCurrency(inv.totalAmount),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nội dung:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Row(
                          children: [
                            Text(
                              inv.paymentReference ?? 'SR-THANHTOAN',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: inv.paymentReference ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản!')),
                                );
                              },
                              child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteInvoice(BuildContext context, InvoiceModel inv, AppDataProvider data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa hóa đơn'),
        content: Text(
          'Bạn có chắc chắn muốn XÓA tạm thời hóa đơn Tháng ${inv.month}/${inv.year} (#${inv.id.length > 8 ? inv.id.substring(0, 8) : inv.id})?\n\nHóa đơn sẽ được chuyển vào thùng rác và có thể khôi phục lại bất kỳ lúc nào.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await data.deleteInvoice(inv.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã chuyển hóa đơn vào thùng rác!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Chuyển vào thùng rác'),
          ),
        ],
      ),
    );
  }

  void _showGenerateInvoiceDialog(BuildContext context, AppDataProvider data) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;
    String? selectedRoomId = data.rooms.isNotEmpty ? data.rooms.first.id : null;

    double elecOld = 0;
    double waterOld = 0;
    final elecOldCtrl = TextEditingController(text: '0');
    final elecNewCtrl = TextEditingController(text: '0');
    final waterOldCtrl = TextEditingController(text: '0');
    final waterNewCtrl = TextEditingController(text: '0');
    bool isLoadingReadings = false;

    void updatePreviousReadings(String roomId, StateSetter setDialogState) async {
      setDialogState(() => isLoadingReadings = true);
      try {
        final readings = await data.getMeterReadingsForRoom(roomId);
        double foundElec = 0;
        double foundWater = 0;
        for (final r in readings) {
          if (r is Map) {
            final type = r['meter_type'];
            final newVal = (r['new_reading'] as num?)?.toDouble() ?? 0;
            if (type == 'ELECTRICITY' && foundElec == 0) {
              foundElec = newVal;
            } else if (type == 'WATER' && foundWater == 0) {
              foundWater = newVal;
            }
          }
        }
        if (foundElec == 0) {
          final roomObj = data.rooms.firstWhere((r) => r.id == roomId, orElse: () => data.rooms.first);
          final numVal = double.tryParse(roomObj.roomNumber) ?? 101;
          foundElec = numVal * 10 + 645;
        }
        if (foundWater == 0) {
          final roomObj = data.rooms.firstWhere((r) => r.id == roomId, orElse: () => data.rooms.first);
          final numVal = double.tryParse(roomObj.roomNumber) ?? 101;
          foundWater = numVal + 24;
        }

        elecOld = foundElec;
        waterOld = foundWater;
        elecOldCtrl.text = elecOld.toStringAsFixed(0);
        elecNewCtrl.text = elecOld.toStringAsFixed(0);
        waterOldCtrl.text = waterOld.toStringAsFixed(0);
        waterNewCtrl.text = waterOld.toStringAsFixed(0);
      } catch (_) {
        elecOld = 1645;
        waterOld = 124;
        elecOldCtrl.text = '1645';
        elecNewCtrl.text = '1645';
        waterOldCtrl.text = '124';
        waterNewCtrl.text = '124';
      } finally {
        setDialogState(() => isLoadingReadings = false);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Initialize readings for first room once
          if (selectedRoomId != null && elecOld == 0 && waterOld == 0 && !isLoadingReadings) {
            updatePreviousReadings(selectedRoomId!, setDialogState);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Chốt số & Lập hóa đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập chỉ số điện nước mới cho phòng để tự động tính toán chi phí và xuất hóa đơn gửi người thuê.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 16),

                    // Chọn phòng
                    DropdownButtonFormField<String>(
                      value: selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn phòng trọ *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: data.rooms.map((r) {
                        return DropdownMenuItem<String>(
                          value: r.id,
                          child: Text('Phòng #${r.roomNumber} (${Formatters.formatCurrency(r.baseRent)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRoomId = val);
                          updatePreviousReadings(val, setDialogState);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Tháng và Năm
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Kỳ Tháng',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: List.generate(12, (i) => i + 1)
                                .map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m')))
                                .toList(),
                            onChanged: (val) => setDialogState(() => selectedMonth = val ?? selectedMonth),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Năm',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [now.year - 1, now.year, now.year + 1]
                                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                .toList(),
                            onChanged: (val) => setDialogState(() => selectedYear = val ?? selectedYear),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isLoadingReadings)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // Khối Chốt Số Điện
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Chỉ số Điện (kWh) - Đơn giá: 4.000đ/kWh',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: elecOldCtrl,
                                    enabled: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Số cũ',
                                      filled: true,
                                      fillColor: Color(0xFFF1F5F9),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: elecNewCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Số mới *',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Khối Chốt Số Nước
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Chỉ số Nước (m³) - Đơn giá: 25.000đ/m³',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: waterOldCtrl,
                                    enabled: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Số cũ',
                                      filled: true,
                                      fillColor: Color(0xFFF1F5F9),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: waterNewCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Số mới *',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: isLoadingReadings
                    ? null
                    : () async {
                        if (selectedRoomId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn phòng trọ')),
                          );
                          return;
                        }
                        final parsedElecNew = double.tryParse(elecNewCtrl.text);
                        final parsedWaterNew = double.tryParse(waterNewCtrl.text);

                        if (parsedElecNew == null || parsedElecNew < elecOld) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chỉ số điện mới ($parsedElecNew) không được nhỏ hơn số cũ ($elecOld)')),
                          );
                          return;
                        }

                        if (parsedWaterNew == null || parsedWaterNew < waterOld) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chỉ số nước mới ($parsedWaterNew) không được nhỏ hơn số cũ ($waterOld)')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        try {
                          await data.generateInvoiceForRoom(
                            roomId: selectedRoomId!,
                            month: selectedMonth,
                            year: selectedYear,
                            elecNew: parsedElecNew,
                            waterNew: parsedWaterNew,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã lưu chỉ số & Tạo hóa đơn Tháng $selectedMonth/$selectedYear thành công!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Lưu & Tạo hóa đơn'),
              ),
            ],
          );
        },
      ),
    );
  }
}
