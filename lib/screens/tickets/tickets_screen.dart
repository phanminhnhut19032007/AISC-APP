import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_badge.dart';

class TicketsScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const TicketsScreen({super.key, this.onNavigateTab});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String _statusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final isOwner = auth.currentUser?.isOwner ?? true;

    // Filter tickets
    var filteredTickets = data.tickets;
    if (_statusFilter != 'ALL') {
      filteredTickets = filteredTickets.where((t) => t.status == _statusFilter).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppHeader(title: isOwner ? 'Bảo trì & Sửa chữa' : 'Báo cáo sự cố'),
      drawer: AppDrawer(
        currentIndex: isOwner ? 3 : 2,
        onTabSelected: (idx) => widget.onNavigateTab?.call(idx),
      ),
      floatingActionButton: isOwner
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateTicketDialog(context, data, auth),
              backgroundColor: AppColors.warning,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Báo sự cố',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () => data.fetchTickets(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả (${data.tickets.length})', 'ALL'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Mới (${data.tickets.where((t) => t.status == "OPEN").length})', 'OPEN'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đã phân công (${data.tickets.where((t) => t.status == "ASSIGNED").length})', 'ASSIGNED'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đang xử lý (${data.tickets.where((t) => t.status == "IN_PROGRESS").length})', 'IN_PROGRESS'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Hoàn thành (${data.tickets.where((t) => t.status == "CLOSED").length})', 'CLOSED'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tickets List
              if (filteredTickets.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.build_circle_outlined, size: 48, color: AppColors.borderLight),
                        SizedBox(height: 10),
                        Text('Không có sự cố nào cần xử lý', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ticket = filteredTickets[index];
                    return _buildTicketCard(context, ticket, isOwner, data);
                  },
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
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.warning,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.warning : AppColors.borderLight),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketModel ticket, bool isOwner, AppDataProvider data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Room/Building + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.meeting_room_outlined, size: 13, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 4),
                        Text(
                          'Phòng #${ticket.roomNumber ?? "—"}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                        ),
                        if (ticket.buildingName != null && ticket.buildingName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${ticket.buildingName}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.ticket(ticket.status),
            ],
          ),

          const SizedBox(height: 8),

          // Badges: Priority + Time
          Row(
            children: [
              StatusBadge.priority(ticket.priority),
              const SizedBox(width: 8),
              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                Formatters.formatTimeAgo(ticket.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),

          if (ticket.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ticket.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (ticket.resolutionNote != null && ticket.resolutionNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ghi chú xử lý: ${ticket.resolutionNote}',
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions (Owner or Tenant)
          if (isOwner && ticket.status != 'CLOSED') ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ticket.status == 'OPEN')
                  OutlinedButton.icon(
                    onPressed: () => data.updateTicketStatus(
                      ticketId: ticket.id,
                      status: 'ASSIGNED',
                    ),
                    icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                    label: const Text('Phân công', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    ),
                  ),
                if (ticket.status == 'ASSIGNED')
                  OutlinedButton.icon(
                    onPressed: () => data.updateTicketStatus(
                      ticketId: ticket.id,
                      status: 'IN_PROGRESS',
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 15),
                    label: const Text('Bắt đầu xử lý', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCloseTicketDialog(context, ticket, data),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text('Hoàn tất sửa', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ] else if (!isOwner && ticket.status == 'CLOSED') ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRateTicketDialog(context, ticket, data),
                  icon: const Icon(Icons.star_rate_rounded, size: 16, color: Color(0xFFEAB308)),
                  label: const Text(
                    'Đánh giá chất lượng xử lý',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFCA8A04)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFDE047)),
                    backgroundColor: const Color(0xFFFEF9C3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context, AppDataProvider data, AuthProvider auth) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'MEDIUM';
    String? selectedRoomId = data.rooms.isNotEmpty ? data.rooms.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Báo cáo sự cố / Hỏng hóc', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.rooms.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedRoomId,
                    decoration: const InputDecoration(labelText: 'Chọn phòng trọ'),
                    items: data.rooms
                        .map((r) => DropdownMenuItem(value: r.id, child: Text('Phòng #${r.roomNumber}')))
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedRoomId = val),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tiêu đề sự cố *', hintText: 'VD: Hỏng vòi nước, Điều hòa không mát'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mô tả chi tiết', hintText: 'Chi tiết tình trạng và vị trí hư hỏng...'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                  items: const [
                    DropdownMenuItem(value: 'LOW', child: Text('Thấp (LOW)')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Trung bình (MEDIUM)')),
                    DropdownMenuItem(value: 'HIGH', child: Text('Cao (HIGH)')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Khẩn cấp (URGENT)')),
                  ],
                  onChanged: (val) => setDialogState(() => priority = val ?? priority),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || selectedRoomId == null) return;
                Navigator.pop(ctx);
                await data.createTicket(
                  roomId: selectedRoomId!,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  priority: priority,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi báo cáo sự cố thành công!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
              child: const Text('Gửi báo cáo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseTicketDialog(BuildContext context, TicketModel ticket, AppDataProvider data) {
    final noteCtrl = TextEditingController(text: 'Đã hoàn thành sửa chữa.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận hoàn thành sửa chữa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú giải quyết (nếu có)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await data.updateTicketStatus(
                ticketId: ticket.id,
                status: 'CLOSED',
                resolutionNote: noteCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: const Text('Đánh dấu đã giải quyết'),
          ),
        ],
      ),
    );
  }

  void _showRateTicketDialog(BuildContext context, TicketModel ticket, AppDataProvider data) {
    int selectedScore = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.star_rate_rounded, color: Color(0xFFEAB308)),
              SizedBox(width: 8),
              Text('Đánh giá dịch vụ sửa chữa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sự cố: "${ticket.title}" đã được xử lý. Bạn có hài lòng với chất lượng và thời gian xử lý không?',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 16),
              // 5 Stars row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => selectedScore = starVal),
                    icon: Icon(
                      starVal <= selectedScore ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 32,
                      color: const Color(0xFFEAB308),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét của bạn (không bắt buộc)',
                  hintText: 'Thợ sửa nhiệt tình, nhanh chóng...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await data.rateTicket(
                    ticketId: ticket.id,
                    score: selectedScore,
                    comment: commentCtrl.text.trim().isNotEmpty ? commentCtrl.text.trim() : null,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá!')),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAB308), foregroundColor: Colors.black),
              child: const Text('Gửi đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
