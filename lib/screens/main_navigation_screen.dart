import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/app_data_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'buildings/buildings_screen.dart';
import 'invoices/invoices_screen.dart';
import 'tickets/tickets_screen.dart';
import 'unipack/unipack_screen.dart';
import 'chat/chat_screen.dart';
import 'emergency/emergency_screen.dart';
import '../widgets/siren_icon.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final data = context.read<AppDataProvider>();
      if (auth.currentUser?.isOwner ?? true) {
        data.startEmergencyPolling();
      }
    });
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final isOwner = auth.currentUser?.isOwner ?? true;

    final screens = isOwner
        ? [
            DashboardScreen(onNavigateTab: _onTabSelected),
            BuildingsScreen(onNavigateTab: _onTabSelected),
            InvoicesScreen(onNavigateTab: _onTabSelected),
            TicketsScreen(onNavigateTab: _onTabSelected),
            UniPackScreen(onNavigateTab: _onTabSelected),
            ChatScreen(onNavigateTab: _onTabSelected),
            EmergencyScreen(onNavigateTab: _onTabSelected),
          ]
        : [
            DashboardScreen(onNavigateTab: _onTabSelected),
            InvoicesScreen(onNavigateTab: _onTabSelected),
            TicketsScreen(onNavigateTab: _onTabSelected),
            UniPackScreen(onNavigateTab: _onTabSelected),
            ChatScreen(onNavigateTab: _onTabSelected),
            EmergencyScreen(onNavigateTab: _onTabSelected),
          ];

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;
    final activeAlert = (isOwner && data.activeEmergencyModal != null) ? data.activeEmergencyModal : null;

    return Stack(
      children: [
        IndexedStack(
          index: safeIndex,
          children: screens,
        ),
        if (activeAlert != null)
          _buildEmergencyOverlay(context, data, activeAlert),
      ],
    );
  }

  Widget _buildEmergencyOverlay(BuildContext context, AppDataProvider data, dynamic alert) {
    final typeConfig = IncidentTypeOption.getTypeConfig(alert.emergencyType);
    final timeStr = DateFormat('HH:mm:ss').format(alert.timestamp);

    return Material(
      color: const Color(0xCC2C0B0E), // Red 950 backdrop with blur
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Slate 900 dark theme matching web
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEF4444), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                  blurRadius: 35,
                  spreadRadius: 6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Red Header Bar with Siren & Live SOS Badge
                    Container(
                      color: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: SirenIcon(
                                color: Color(0xFFDC2626),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BÁO ĐỘNG KHẨN CẤP (SOS)!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Tín hiệu cảnh báo nguy cấp từ Cư dân',
                                  style: TextStyle(
                                    color: Color(0xFFFEE2E2),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'LIVE SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Content Body
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          // Room Banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF450A0A).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'VỊ TRÍ PHÁT TÍN HIỆU',
                                      style: TextStyle(
                                        color: Color(0xFFF87171),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Phòng #${alert.roomCode}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      alert.buildingName ?? 'Tòa nhà REASY',
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Thời gian phát',
                                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        color: Color(0xFFFCA5A5),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Emergency Details Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                // Incident Type Row
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(typeConfig.icon, color: const Color(0xFFEF4444), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Phân loại sự cố',
                                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                        ),
                                        Text(
                                          typeConfig.label.toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const Divider(color: Colors.white10, height: 20),

                                // Sender Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Người gửi báo động',
                                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                        ),
                                        Text(
                                          alert.senderName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (alert.senderPhone != null && alert.senderPhone!.isNotEmpty)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF059669),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        onPressed: () {},
                                        icon: const Icon(Icons.phone_rounded, size: 13),
                                        label: Text(
                                          'Gọi: ${alert.senderPhone}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),

                                if (alert.note != null && alert.note!.isNotEmpty) ...[
                                  const Divider(color: Colors.white10, height: 20),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ghi chú từ cư dân:',
                                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '"${alert.note}"',
                                            style: const TextStyle(
                                              color: Color(0xFFE2E8F0),
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            '⚠️ Vui lòng liên hệ người thuê hoặc cơ quan chức năng ngay lập tức. Sau khi tiếp nhận, hãy nhấn nút xác nhận bên dưới để đóng cửa sổ báo động.',
                            style: TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 11,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Big Action Button to Acknowledge
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                              ),
                              onPressed: () {
                                data.acknowledgeEmergencyAlert(alert.id);
                                HapticFeedback.mediumImpact();
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text(
                                'XÁC NHẬN ĐÃ TIẾP NHẬN (ĐÓNG BÁO ĐỘNG)',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
