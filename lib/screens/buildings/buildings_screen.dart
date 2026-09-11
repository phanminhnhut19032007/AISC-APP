import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/building_model.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/animated_pressable.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_badge.dart';

class BuildingsScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const BuildingsScreen({super.key, this.onNavigateTab});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  String _selectedStatusFilter = 'ALL';
  int _selectedFloorFilter = 0; // 0: All floors

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final isOwner = auth.currentUser?.isOwner ?? true;

    // Filter rooms
    var filteredRooms = data.rooms;
    if (_selectedStatusFilter != 'ALL') {
      filteredRooms = filteredRooms.where((r) => r.status == _selectedStatusFilter).toList();
    }
    if (_selectedFloorFilter > 0) {
      filteredRooms = filteredRooms.where((r) => r.floor == _selectedFloorFilter).toList();
    }

    // Get unique floors
    final floors = data.rooms.map((r) => r.floor).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const AppHeader(title: 'Tòa nhà & Phòng'),
      drawer: AppDrawer(
        currentIndex: 1,
        onTabSelected: (idx) => widget.onNavigateTab?.call(idx),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showAddRoomDialog(context, data),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Thêm phòng',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => data.fetchRoomsForSelectedBuilding(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Mode Toggle (Hoạt động / Tòa nhà đã xóa)
              if (isOwner) ...[
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Hoạt động'),
                      selected: !data.showDeletedBuildings,
                      onSelected: (_) => data.setShowDeletedBuildings(false),
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !data.showDeletedBuildings ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: !data.showDeletedBuildings ? const Color(0xFF2563EB) : AppColors.borderLight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🗑️ Tòa nhà đã xóa'),
                      selected: data.showDeletedBuildings,
                      onSelected: (_) => data.setShowDeletedBuildings(true),
                      selectedColor: const Color(0xFFDC2626),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: data.showDeletedBuildings ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: data.showDeletedBuildings ? const Color(0xFFDC2626) : AppColors.borderLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              if (data.showDeletedBuildings) ...[
                // Deleted Buildings View
                if (data.buildings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.delete_sweep_outlined, size: 48, color: AppColors.borderLight),
                          SizedBox(height: 10),
                          Text(
                            'Thùng rác trống. Không có tòa nhà nào bị xóa.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.buildings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final b = data.buildings[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.apartment_rounded, color: Color(0xFFDC2626), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    b.address,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await data.restoreBuilding(b.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã khôi phục tòa nhà "${b.name}" thành công!')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                              label: const Text('Khôi phục', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ] else ...[
                // Building Info Card
                if (data.selectedBuilding != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.selectedBuilding!.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.selectedBuilding!.address,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildPill('${data.selectedBuilding!.totalFloors} Tầng', AppColors.primary),
                                const SizedBox(width: 6),
                                _buildPill('${data.rooms.length} Phòng', AppColors.success),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                          onSelected: (value) {
                            if (value == 'add_building') {
                              _showAddBuildingDialog(context, data);
                            } else if (value == 'delete_building') {
                              _confirmDeleteBuilding(context, data);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'add_building',
                              child: Row(
                                children: [
                                  Icon(Icons.add_business_rounded, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Thêm tòa nhà mới'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete_building',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                  SizedBox(width: 8),
                                  Text('Xóa tòa nhà này', style: TextStyle(color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Filter Chips by Status
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả (${data.rooms.length})', 'ALL', _selectedStatusFilter, (val) {
                      setState(() => _selectedStatusFilter = val);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Còn trống (${data.availableRooms})', 'AVAILABLE', _selectedStatusFilter, (val) {
                      setState(() => _selectedStatusFilter = val);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đang thuê (${data.rentedRooms})', 'RENTED', _selectedStatusFilter, (val) {
                      setState(() => _selectedStatusFilter = val);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Bảo trì (${data.maintenanceRooms})', 'MAINTENANCE', _selectedStatusFilter, (val) {
                      setState(() => _selectedStatusFilter = val);
                    }),
                  ],
                ),
              ),

              if (floors.length > 1) ...[
                const SizedBox(height: 10),
                // Floor Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFloorChip('Tất cả tầng', 0),
                      ...floors.map((floor) => _buildFloorChip('Tầng $floor', floor)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Rooms Grid
              if (filteredRooms.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.door_sliding_outlined, size: 48, color: AppColors.borderLight),
                        SizedBox(height: 10),
                        Text('Không tìm thấy phòng trọ nào phù hợp', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    return _buildRoomCard(context, room, isOwner, data);
                  },
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardActionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      scaleDown: 0.9,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderLight),
      ),
    );
  }

  Widget _buildFloorChip(String label, int floor) {
    final isSelected = _selectedFloorFilter == floor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFloorFilter = floor),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textMuted,
        ),
        selectedColor: AppColors.primaryLight,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderLight),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room, bool isOwner, AppDataProvider data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: room.isAvailable
              ? AppColors.success.withOpacity(0.3)
              : (room.isRented ? AppColors.primary.withOpacity(0.3) : AppColors.warning.withOpacity(0.3)),
          width: 1.5,
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Room Number + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Phòng #${room.roomNumber}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              StatusBadge.room(room.status),
            ],
          ),

          const SizedBox(height: 6),

          // Rent & Floor Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Formatters.formatCurrency(room.baseRent),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                'Tầng ${room.floor}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),

          const Divider(height: 10),

          // Utilities rates mini view
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${Formatters.formatCurrency(room.electricityRate)}/kWh',
                      style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.water_drop_rounded, size: 12, color: AppColors.sky),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${Formatters.formatCurrency(room.waterRate)}/m³',
                      style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions
          if (isOwner)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCardActionBtn(
                  icon: Icons.speed_rounded,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                  onTap: () => _showMeterReadingDialog(context, room, data),
                ),
                const SizedBox(width: 6),
                _buildCardActionBtn(
                  icon: Icons.edit_outlined,
                  color: AppColors.textSecondary,
                  bgColor: AppColors.bgLight,
                  onTap: () => _showEditRoomDialog(context, room, data),
                ),
                const SizedBox(width: 6),
                _buildCardActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  bgColor: AppColors.dangerBg,
                  onTap: () => _confirmDeleteRoom(context, room, data),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddBuildingDialog(BuildContext context, AppDataProvider data) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final provinceCtrl = TextEditingController(text: 'TP.HCM');
    final floorsCtrl = TextEditingController(text: '3');
    final autoRoomsCtrl = TextEditingController(text: '6');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thêm tòa nhà mới', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên tòa nhà *', hintText: 'VD: Nhà trọ Minh Châu'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết *', hintText: 'VD: 45 Đường D1, Bình Thạnh'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: provinceCtrl,
                decoration: const InputDecoration(labelText: 'Tỉnh / Thành phố'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: floorsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tầng'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: autoRoomsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tự động tạo số phòng', hintText: 'VD: 6 (sẽ tạo 101, 102...)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await data.createBuilding(
                name: nameCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                province: provinceCtrl.text.trim(),
                totalFloors: int.tryParse(floorsCtrl.text) ?? 1,
                autoGenerateRooms: int.tryParse(autoRoomsCtrl.text),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Tạo tòa nhà'),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context, AppDataProvider data) {
    final roomNumCtrl = TextEditingController();
    final floorCtrl = TextEditingController(text: '1');
    final rentCtrl = TextEditingController(text: '3000000');
    final elecCtrl = TextEditingController(text: '4000');
    final waterCtrl = TextEditingController(text: '25000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thêm phòng trọ mới', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomNumCtrl,
                decoration: const InputDecoration(labelText: 'Số phòng *', hintText: 'VD: 101, 201...'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: floorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tầng'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá thuê (đ/tháng) *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: elecCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đơn giá điện (đ/kWh)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: waterCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đơn giá nước (đ/m³)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (roomNumCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await data.createRoom(
                roomNumber: roomNumCtrl.text.trim(),
                floor: int.tryParse(floorCtrl.text) ?? 1,
                baseRent: double.tryParse(rentCtrl.text) ?? 3000000,
                electricityRate: double.tryParse(elecCtrl.text) ?? 4000,
                waterRate: double.tryParse(waterCtrl.text) ?? 25000,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Thêm phòng'),
          ),
        ],
      ),
    );
  }

  void _showEditRoomDialog(BuildContext context, RoomModel room, AppDataProvider data) {
    final rentCtrl = TextEditingController(text: room.baseRent.toStringAsFixed(0));
    final elecCtrl = TextEditingController(text: room.electricityRate.toStringAsFixed(0));
    final waterCtrl = TextEditingController(text: room.waterRate.toStringAsFixed(0));
    final floorCtrl = TextEditingController(text: room.floor.toString());
    String status = room.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Chỉnh sửa phòng #${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá thuê phòng (đ/tháng)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: elecCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Điện (đ/kWh)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: waterCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nước (đ/m³)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: floorCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tầng'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Trạng thái phòng'),
                  items: const [
                    DropdownMenuItem(value: 'AVAILABLE', child: Text('Còn trống (AVAILABLE)')),
                    DropdownMenuItem(value: 'RENTED', child: Text('Đang thuê (RENTED)')),
                    DropdownMenuItem(value: 'MAINTENANCE', child: Text('Đang bảo trì (MAINTENANCE)')),
                  ],
                  onChanged: (val) => setDialogState(() => status = val ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await data.updateRoom(room.id, {
                  'base_rent': double.tryParse(rentCtrl.text) ?? room.baseRent,
                  'electricity_rate': double.tryParse(elecCtrl.text) ?? room.electricityRate,
                  'water_rate': double.tryParse(waterCtrl.text) ?? room.waterRate,
                  'floor': int.tryParse(floorCtrl.text) ?? room.floor,
                  'status': status,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật phòng #${room.roomNumber} thành công!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeterReadingDialog(BuildContext context, RoomModel room, AppDataProvider data) {
    final elecCtrl = TextEditingController();
    final waterCtrl = TextEditingController();
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ghi chỉ số điện nước - Phòng #${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ghi nhận chỉ số tháng ${now.month}/${now.year}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: elecCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Chỉ số điện mới (kWh)',
                prefixIcon: Icon(Icons.bolt_rounded, color: AppColors.warning),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: waterCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Chỉ số nước mới (m³)',
                prefixIcon: Icon(Icons.water_drop_rounded, color: AppColors.sky),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (elecCtrl.text.isNotEmpty) {
                await data.recordMeterReading(
                  roomId: room.id,
                  meterType: 'ELECTRICITY',
                  readingValue: double.tryParse(elecCtrl.text) ?? 0,
                  month: now.month,
                  year: now.year,
                );
              }
              if (waterCtrl.text.isNotEmpty) {
                await data.recordMeterReading(
                  roomId: room.id,
                  meterType: 'WATER',
                  readingValue: double.tryParse(waterCtrl.text) ?? 0,
                  month: now.month,
                  year: now.year,
                );
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu chỉ số điện nước thành công!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Lưu chỉ số'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, RoomModel room, AppDataProvider data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa phòng', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa phòng #${room.roomNumber}? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await data.deleteRoom(room.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBuilding(BuildContext context, AppDataProvider data) {
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Xác nhận xóa tòa nhà', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn chuyển tòa nhà "${data.selectedBuilding?.name}" vào thùng rác?',
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              const Text(
                'Để xác nhận, vui lòng nhập chữ "Y" vào ô bên dưới:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nhập Y',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (confirmCtrl.text.trim().toUpperCase() != 'Y') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập chính xác chữ "Y" để xác nhận')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                if (data.selectedBuilding != null) {
                  await data.deleteBuilding(data.selectedBuilding!.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chuyển tòa nhà vào thùng rác!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              child: const Text('Xác nhận xóa'),
            ),
          ],
        ),
      ),
    );
  }
}
