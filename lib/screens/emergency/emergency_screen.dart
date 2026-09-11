import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/animated_pressable.dart';
import '../../widgets/siren_icon.dart';

class IncidentTypeOption {
  final String id;
  final String label;
  final IconData icon;

  const IncidentTypeOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  static const List<IncidentTypeOption> all = [
    IncidentTypeOption(
      id: 'FIRE',
      label: 'Hỏa hoạn / Cháy nổ',
      icon: Icons.local_fire_department_rounded,
    ),
    IncidentTypeOption(
      id: 'THEFT',
      label: 'Đột nhập / Trộm cắp',
      icon: Icons.gpp_maybe_outlined,
    ),
    IncidentTypeOption(
      id: 'MEDICAL',
      label: 'Cấp cứu y tế',
      icon: Icons.monitor_heart_outlined,
    ),
    IncidentTypeOption(
      id: 'GAS_LEAK',
      label: 'Rò rỉ Gas / Chập điện',
      icon: Icons.bolt_rounded,
    ),
    IncidentTypeOption(
      id: 'ELEVATOR',
      label: 'Kẹt thang máy / Khóa kẹt',
      icon: Icons.error_outline_rounded,
    ),
    IncidentTypeOption(
      id: 'OTHER',
      label: 'Sự cố nguy cấp khác',
      icon: Icons.warning_amber_rounded,
    ),
  ];

  static IncidentTypeOption getTypeConfig(String? typeId) {
    if (typeId == null || typeId.isEmpty) {
      return const IncidentTypeOption(
        id: 'OTHER',
        label: 'Sự cố nguy cấp khác',
        icon: Icons.warning_amber_rounded,
      );
    }
    final upper = typeId.toUpperCase();
    if (upper == 'FIRE') {
      return const IncidentTypeOption(
        id: 'FIRE',
        label: 'Hỏa hoạn / Cháy nổ',
        icon: Icons.local_fire_department_rounded,
      );
    }
    if (upper == 'THEFT' || upper == 'BURGLARY') {
      return const IncidentTypeOption(
        id: 'THEFT',
        label: 'Đột nhập / Trộm cắp',
        icon: Icons.gpp_maybe_outlined,
      );
    }
    if (upper == 'MEDICAL') {
      return const IncidentTypeOption(
        id: 'MEDICAL',
        label: 'Cấp cứu y tế',
        icon: Icons.monitor_heart_outlined,
      );
    }
    if (upper == 'GAS_LEAK' || upper == 'GAS_ELECTRIC') {
      return const IncidentTypeOption(
        id: 'GAS_LEAK',
        label: 'Rò rỉ Gas / Chập điện',
        icon: Icons.bolt_rounded,
      );
    }
    if (upper == 'ELEVATOR') {
      return const IncidentTypeOption(
        id: 'ELEVATOR',
        label: 'Kẹt thang máy / Khóa kẹt',
        icon: Icons.error_outline_rounded,
      );
    }
    return const IncidentTypeOption(
      id: 'OTHER',
      label: 'Sự cố nguy cấp khác',
      icon: Icons.warning_amber_rounded,
    );
  }
}

class EmergencyScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const EmergencyScreen({super.key, this.onNavigateTab});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with TickerProviderStateMixin {
  final TextEditingController _noteCtrl = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _glowPulse;
  
  String _selectedIncidentType = 'FIRE';
  bool _isSending = false;

  static List<IncidentTypeOption> get _incidentTypes => IncidentTypeOption.all;
  static IncidentTypeOption getTypeConfig(String? typeId) => IncidentTypeOption.getTypeConfig(typeId);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.98, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowPulse = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppDataProvider>().loadEmergencyAlerts();
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final user = auth.currentUser;
    final isOwner = user?.isOwner ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AppDrawer(
        currentIndex: isOwner ? 6 : 5,
        onTabSelected: _onTabSelected,
      ),
      appBar: AppHeader(
        title: isOwner ? 'Tin Khẩn Cấp (SOS Alert)' : 'Báo Khẩn Cấp (SOS)',
        showBuildingSelector: isOwner,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await data.loadEmergencyAlerts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: isOwner ? _buildOwnerView(context, data) : _buildTenantView(context, auth, data),
        ),
      ),
    );
  }

  // ================= TENANT VIEW =================
  Widget _buildTenantView(BuildContext context, AuthProvider auth, AppDataProvider data) {
    final roomCode = auth.tenantRoomCode ?? '101';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Red Header Banner with Emergency Hotlines
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626), // Solid vibrant red
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444), // Translucent lighter red square
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SirenIcon(
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRUNG TÂM BÁO ĐỘNG KHẨN CẤP (SOS)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sử dụng tính năng này khi gặp sự cố nguy cấp đe dọa an toàn tính mạng hoặc tài sản tại phòng #$roomCode. Tín hiệu sẽ kích hoạt chuông cảnh báo toàn màn hình của Chủ trọ ngay tức thì.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Main SOS Configuration Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SELECT INCIDENT TYPE
              const Text(
                '1. CHỌN LOẠI SỰ CỐ KHẨN CẤP:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              
              // Incident Grid/List
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 68,
                    ),
                    itemCount: _incidentTypes.length,
                    itemBuilder: (context, index) {
                      final type = _incidentTypes[index];
                      final isSelected = _selectedIncidentType == type.id;

                      return AnimatedPressable(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedIncidentType = type.id);
                        },
                        scaleDown: 0.96,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                              width: isSelected ? 2.0 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFDC2626) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? null
                                      : Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                ),
                                child: Center(
                                  child: Icon(
                                    type.icon,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    color: isSelected ? const Color(0xFF991B1B) : const Color(0xFF1E293B),
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 20),

              // 2. SHORT DESCRIPTION
              const Text(
                '2. MÔ TẢ NGẮN TÌNH HÌNH (TÙY CHỌN):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Có khói đen ở cửa sổ, hoặc có tiếng cạy cửa bên ngoài...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // 3. EXACT REPLICA SOS BUTTON MATCHING WEB SCREENSHOT
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseScale.value,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFDE8E8).withValues(alpha: _glowPulse.value), // Outermost pulsing glow ring
                        ),
                        child: Center(
                          child: Container(
                            width: 215,
                            height: 215,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFCA5A5).withValues(alpha: 0.35), // Middle translucent red ring
                            ),
                            child: Center(
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: _isSending ? null : () => _confirmAndSendSOS(context, auth, data),
                    child: Container(
                      width: 175,
                      height: 175,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE02424), // Vibrant crimson red
                        border: Border.all(color: Colors.white, width: 4.5), // Crisp pure white solid border
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Alarm Siren Icon (Matching exactly the vector from web)
                          const SirenIcon(
                            color: Colors.white,
                            size: 48,
                            strokeWidth: 3.5,
                          ),
                          const SizedBox(height: 8),
                          // "BÁO KHẨN CẤP"
                          const Text(
                            'BÁO KHẨN CẤP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // "NHẤN ĐỂ PHÁT SOS"
                          const Text(
                            'NHẤN ĐỂ PHÁT SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Footnote Alert
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Sau khi nhấn nút, hệ thống sẽ yêu cầu bạn xác nhận lần cuối trước khi kích hoạt còi báo động đến Chủ trọ.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Incident History
        _buildAlertHistoryList(data, isOwner: false),
      ],
    );
  }

  // ================= OWNER VIEW =================
  Widget _buildOwnerView(BuildContext context, AppDataProvider data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Banner: TRUNG TÂM TIẾP NHẬN TIN KHẨN CẤP
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF2C0B0E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7F1D1D).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF450A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF991B1B)),
                ),
                child: const Center(
                  child: SirenIcon(
                    color: Color(0xFFF87171),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'TRUNG TÂM TIẾP NHẬN TIN KHẨN CẤP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Theo dõi các tín hiệu báo động trực tiếp từ tất cả các phòng trọ. Khi có sự cố mới, màn hình cảnh báo sẽ tự động bật toàn màn hình.',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF450A0A),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF7F1D1D)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await data.loadEmergencyAlerts();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật danh sách báo động!')),
                    );
                  }
                },
                child: const Text(
                  'Làm mới danh sách',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Incident History List
        _buildAlertHistoryList(data, isOwner: true),
      ],
    );
  }

  // ================= COMMON HISTORY LIST =================
  Widget _buildAlertHistoryList(AppDataProvider data, {required bool isOwner}) {
    final alerts = data.emergencyAlerts;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              const Text(
                'Lịch sử tin báo khẩn cấp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${alerts.length} sự cố gần nhất',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (alerts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF16A34A),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Hiện không có sự cố khẩn cấp nào',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tất cả các phòng đều an toàn',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              itemBuilder: (ctx, idx) {
                final item = alerts[idx];
                final typeConfig = getTypeConfig(item.emergencyType);
                final dateStr = DateFormat('HH:mm:ss d/M/yyyy').format(item.timestamp);
                final isAct = item.isActive;
                final isAck = item.status == 'ACKNOWLEDGED';

                // Status Badge configuration matching Web STATUS_BADGE
                String statusLabel;
                Color badgeBg;
                Color badgeBorder;
                Color badgeTextColor;

                if (isAct) {
                  statusLabel = 'Đang báo động';
                  badgeBg = const Color(0xFFFEE2E2);
                  badgeBorder = const Color(0xFFFECACA);
                  badgeTextColor = const Color(0xFFDC2626);
                } else if (isAck) {
                  statusLabel = 'Chủ trọ đã tiếp nhận';
                  badgeBg = const Color(0xFFDBEAFE);
                  badgeBorder = const Color(0xFFBFDBFE);
                  badgeTextColor = const Color(0xFF1D4ED8);
                } else {
                  statusLabel = 'Đã xử lý an toàn';
                  badgeBg = const Color(0xFFD1FAE5);
                  badgeBorder = const Color(0xFFA7F3D0);
                  badgeTextColor = const Color(0xFF047857);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isAct ? const Color(0xFFFEF2F2) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAct ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Incident Type Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isAct ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            typeConfig.icon,
                            color: isAct ? Colors.white : const Color(0xFF475569),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Title + Status Badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Phòng #${item.roomCode} • ${typeConfig.label}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: badgeBorder),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: badgeTextColor,
                                      fontSize: 10.5,
                                      fontWeight: isAct ? FontWeight.w900 : FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // 2. Sender Information & Note
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Người gửi: ',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  TextSpan(
                                    text: item.senderName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  if (item.senderPhone != null && item.senderPhone!.isNotEmpty)
                                    TextSpan(
                                      text: ' (${item.senderPhone})',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  if (item.note != null && item.note!.trim().isNotEmpty) ...[
                                    const TextSpan(
                                      text: ' — ',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                    TextSpan(
                                      text: '"${item.note!.trim()}"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),

                            // 3. Timestamp and Acknowledged by line
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12.5, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.acknowledgedBy != null && item.acknowledgedBy!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '• Đã tiếp nhận bởi: ${item.acknowledgedBy}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // 4. Actions for Landlord
                            if (isOwner) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (item.senderPhone != null && item.senderPhone!.isNotEmpty)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFECFDF5),
                                        foregroundColor: const Color(0xFF047857),
                                        elevation: 0,
                                        side: const BorderSide(color: Color(0xFFA7F3D0)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.phone_rounded, size: 13),
                                      label: Text('Gọi ${item.senderPhone}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () {},
                                    ),
                                  if (item.isActive)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () async {
                                        await data.acknowledgeEmergencyAlert(item.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Đã xác nhận tiếp nhận tin khẩn cấp!')),
                                          );
                                        }
                                      },
                                      child: const Text('Tiếp nhận', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  if (item.status == 'ACKNOWLEDGED')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () async {
                                        await data.resolveEmergencyAlert(item.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Đã đánh dấu xử lý xong sự cố khẩn cấp!')),
                                          );
                                        }
                                      },
                                      child: const Text('Đã xử lý xong', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ================= TRIGGER SOS CONFIRMATION =================
  void _confirmAndSendSOS(BuildContext context, AuthProvider auth, AppDataProvider data) {
    HapticFeedback.heavyImpact();

    final selectedType = _incidentTypes.firstWhere(
      (t) => t.id == _selectedIncidentType,
      orElse: () => _incidentTypes.last,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 8),
            Text(
              'XÁC NHẬN PHÁT SOS',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đang chọn loại sự cố: ${selectedType.label}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn có chắc chắn muốn phát tín hiệu báo động khẩn cấp tới Chủ trọ không?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                'Hệ thống sẽ ngay lập tức bật còi và kích hoạt màn hình cảnh báo khẩn cấp toàn màn hình trên máy Chủ trọ.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSending = true);

              final user = auth.currentUser;
              final roomCode = auth.tenantRoomCode ?? '101';
              final senderName = user?.fullName ?? 'Tran Thi Mai';
              
              final backendType = selectedType.id;

              final combinedNote = _noteCtrl.text.trim().isNotEmpty
                  ? _noteCtrl.text.trim()
                  : null;

              await data.sendEmergencyAlert(
                senderName: senderName,
                roomCode: roomCode,
                emergencyType: backendType,
                note: combinedNote,
              );

              setState(() {
                _isSending = false;
                _noteCtrl.clear();
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFFDC2626),
                    content: Text('ĐÃ PHÁT TÍN HIỆU BÁO ĐỘNG KHẨN CẤP THÀNH CÔNG!'),
                  ),
                );
              }
            },
            child: const Text('XÁC NHẬN PHÁT SOS', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

