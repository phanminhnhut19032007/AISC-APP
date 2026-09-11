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
    final timeStr = DateFormat('HH:mm:ss - dd/MM/yyyy').format(alert.timestamp);

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing Red SOS Header Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444), width: 2),
                  ),
                  child: const Center(
                    child: SirenIcon(
                      color: Color(0xFFDC2626),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CẢNH BÁO KHẨN CẤP (SOS)!',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Có tín hiệu báo động khẩn cấp từ ${alert.senderName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Vị trí phòng:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text(
                            'Phòng #${alert.roomCode}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thời gian:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                      if (alert.note != null && alert.note!.isNotEmpty) ...[
                        const Divider(height: 16, color: Color(0xFFFCA5A5)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nội dung ghi chú: "${alert.note}"',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      data.acknowledgeEmergencyAlert(alert.id);
                      HapticFeedback.mediumImpact();
                    },
                    child: const Text(
                      'XÁC NHẬN ĐÃ TIẾP NHẬN',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
