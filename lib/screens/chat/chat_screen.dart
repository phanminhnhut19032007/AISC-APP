import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_data_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';

class ChatScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const ChatScreen({super.key, this.onNavigateTab});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessageModel> _messages = [];
  List<dynamic> _members = [];
  String _chatTarget = 'group'; // 'group' or member user_id
  String _chatTargetName = 'Kênh chung';
  bool _isLoading = false;
  Timer? _pollingTimer;
  bool _isBackgroundPolling = false;
  String? _currentBuildingId;

  @override
  void initState() {
    super.initState();
    // Auto-poll every 3 seconds for instant real-time sync with Web
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollNewMessages();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = context.watch<AppDataProvider>();

    // Auto-select first building if none selected
    if (data.selectedBuilding == null && data.buildings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && data.selectedBuilding == null && data.buildings.isNotEmpty) {
          data.setSelectedBuilding(data.buildings.first);
        }
      });
      return;
    }

    final building = data.selectedBuilding;
    if (building != null && building.id != _currentBuildingId) {
      _currentBuildingId = building.id;
      _chatTarget = 'group';
      _chatTargetName = 'Kênh chung';
      _loadData();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadMembers();
    await _loadMessages();
  }

  Future<void> _loadMembers() async {
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id ?? _currentBuildingId;
    if (buildingId == null) return;
    try {
      final list = await _chatService.getMembers(buildingId);
      if (mounted) {
        setState(() {
          _members = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id ?? _currentBuildingId;
    if (buildingId == null) return;

    setState(() => _isLoading = true);
    try {
      final recipientId = _chatTarget == 'group' ? null : _chatTarget;
      final list = await _chatService.getMessages(buildingId, recipientId: recipientId);
      if (mounted) {
        setState(() {
          _messages = list;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pollNewMessages() async {
    if (_isBackgroundPolling || !mounted) return;
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id ?? _currentBuildingId;
    if (buildingId == null) return;

    _isBackgroundPolling = true;
    try {
      // If members list is empty, reload members in background too
      if (_members.isEmpty) {
        final mList = await _chatService.getMembers(buildingId);
        if (mounted && mList.isNotEmpty) {
          setState(() => _members = mList);
        }
      }

      final recipientId = _chatTarget == 'group' ? null : _chatTarget;
      final list = await _chatService.getMessages(buildingId, recipientId: recipientId);
      if (mounted) {
        final bool isDifferentLength = list.length != _messages.length;
        final bool isLastDiff = list.isNotEmpty &&
            _messages.isNotEmpty &&
            list.last.id != _messages.last.id;
        final bool isRecalledDiff = list.any((m) {
          final old = _messages.where((o) => o.id == m.id).firstOrNull;
          return old != null && old.isRecalled != m.isRecalled;
        });

        if (isDifferentLength || isLastDiff || isRecalledDiff) {
          final wasAtBottom = !_scrollController.hasClients ||
              (_scrollController.position.maxScrollExtent - _scrollController.position.pixels < 100);
          setState(() {
            _messages = list;
          });
          if (wasAtBottom || isLastDiff) {
            _scrollToBottom();
          }
        }
      }
    } catch (_) {
    } finally {
      _isBackgroundPolling = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id ?? _currentBuildingId;
    if (buildingId == null) return;

    _msgController.clear();
    try {
      final recipientId = _chatTarget == 'group' ? null : _chatTarget;
      final msg = await _chatService.sendMessage(
        buildingId: buildingId,
        message: text,
        recipientId: recipientId,
      );
      if (mounted) {
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi gửi tin nhắn')),
        );
      }
    }
  }

  Future<void> _handleRecall(ChatMessageModel msg) async {
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id ?? _currentBuildingId;
    if (buildingId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thu hồi tin nhắn?'),
        content: const Text('Bạn có chắc muốn thu hồi tin nhắn này đối với mọi người?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.recallMessage(buildingId, msg.id);
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx != -1) {
              _messages[idx] = ChatMessageModel(
                id: msg.id,
                buildingId: msg.buildingId,
                senderId: msg.senderId,
                senderName: msg.senderName,
                senderRole: msg.senderRole,
                recipientId: msg.recipientId,
                recipientName: msg.recipientName,
                message: 'Tin nhắn đã bị thu hồi',
                isRecalled: true,
                createdAt: msg.createdAt,
              );
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thu hồi tin nhắn thành công')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể thu hồi tin nhắn')),
          );
        }
      }
    }
  }

  void _showMembersBottomSheet(BuildContext context, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final otherMembers = _members.where((m) => m is Map && m['user_id'] != currentUserId).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Danh sách thành viên',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Chọn thành viên để nhắn tin riêng',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Members List
                Expanded(
                  child: otherMembers.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có thành viên nào khác trong tòa nhà',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: otherMembers.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final m = otherMembers[index] as Map;
                            final uid = m['user_id'] as String? ?? '';
                            final name = m['full_name'] as String? ?? 'Thành viên';
                            final role = m['role'] as String? ?? '';
                            final room = m['room_number'] as String? ?? (role == 'OWNER' ? 'Chủ nhà' : '');
                            final isOwner = role == 'OWNER';
                            final isSelected = _chatTarget == uid;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              selected: isSelected,
                              selectedTileColor: const Color(0xFFEFF6FF),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: isOwner ? const Color(0xFFFEE2E2) : const Color(0xFFE0E7FF),
                                child: Icon(
                                  isOwner ? Icons.shield_rounded : Icons.person_rounded,
                                  color: isOwner ? const Color(0xFFDC2626) : const Color(0xFF4F46E5),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isOwner ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isOwner ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      isOwner ? 'CHỦ NHÀ' : 'CƯ DÂN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isOwner ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    room,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _chatTarget = uid;
                                    _chatTargetName = '$name ($room)';
                                  });
                                  _loadMessages();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                  foregroundColor: isSelected ? Colors.white : const Color(0xFF1E293B),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  isSelected ? 'Đang nhắn' : 'Nhắn tin',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final user = auth.currentUser;
    final isOwner = user?.isOwner ?? true;
    final selectedBuilding = data.selectedBuilding;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern slate background
      appBar: const AppHeader(title: 'Chat nội bộ tòa nhà'),
      drawer: AppDrawer(
        currentIndex: isOwner ? 5 : 4,
        onTabSelected: (idx) => widget.onNavigateTab?.call(idx),
      ),
      body: Column(
        children: [
          // 1. Building Selector Bar (For Owners with multiple buildings)
          if (data.buildings.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tòa nhà: ${selectedBuilding?.name ?? "Đang tải..."}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwner && data.buildings.length > 1)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF2563EB)),
                      tooltip: 'Đổi tòa nhà',
                      onSelected: (bId) {
                        final chosen = data.buildings.firstWhere((b) => b.id == bId, orElse: () => data.buildings.first);
                        data.setSelectedBuilding(chosen);
                      },
                      itemBuilder: (context) => data.buildings
                          .map((b) => PopupMenuItem(
                                value: b.id,
                                child: Text(
                                  b.name,
                                  style: TextStyle(
                                    fontWeight: b.id == selectedBuilding?.id ? FontWeight.bold : FontWeight.normal,
                                    color: b.id == selectedBuilding?.id ? const Color(0xFF2563EB) : AppColors.textPrimary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: _loadData,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Tải lại',
                  ),
                ],
              ),
            ),

          const Divider(height: 1, color: AppColors.borderLight),

          // 2. Members & Channel Selector Bar (Horizontal chips + Full members button)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Group Channel Chip (Tất cả)
                        ChoiceChip(
                          avatar: Icon(
                            Icons.forum_rounded,
                            size: 15,
                            color: _chatTarget == 'group' ? Colors.white : const Color(0xFF4F46E5),
                          ),
                          label: const Text('Kênh chung'),
                          selected: _chatTarget == 'group',
                          onSelected: (_) {
                            setState(() {
                              _chatTarget = 'group';
                              _chatTargetName = 'Kênh chung';
                            });
                            _loadMessages();
                          },
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _chatTarget == 'group' ? Colors.white : AppColors.textPrimary,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _chatTarget == 'group' ? const Color(0xFF2563EB) : AppColors.borderLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Individual Members Chips
                        ..._members
                            .where((m) => m is Map && m['user_id'] != user?.id)
                            .map((m) {
                          final uid = m['user_id'] as String? ?? '';
                          final name = m['full_name'] as String? ?? 'Thành viên';
                          final role = m['role'] as String? ?? '';
                          final room = m['room_number'] as String? ?? (role == 'OWNER' ? 'Chủ nhà' : '');
                          final isSelected = _chatTarget == uid;
                          final isMbrOwner = role == 'OWNER';

                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              avatar: Icon(
                                isMbrOwner ? Icons.shield_rounded : Icons.person_rounded,
                                size: 15,
                                color: isSelected
                                    ? Colors.white
                                    : (isMbrOwner ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                              ),
                              label: Text('$name ($room)'),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _chatTarget = uid;
                                  _chatTargetName = '$name ($room)';
                                });
                                _loadMessages();
                              },
                              selectedColor: const Color(0xFF2563EB),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF2563EB) : AppColors.borderLight,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Button to open full members sheet
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.people_alt_rounded, size: 20, color: Color(0xFF475569)),
                  tooltip: 'Danh sách thành viên',
                  onPressed: () => _showMembersBottomSheet(context, user?.id ?? ''),
                ),
              ],
            ),
          ),

          // 3. Active Chat Target Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _chatTarget == 'group' ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
            child: Row(
              children: [
                Icon(
                  _chatTarget == 'group' ? Icons.group_rounded : Icons.lock_outline_rounded,
                  size: 16,
                  color: _chatTarget == 'group' ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _chatTarget == 'group'
                            ? 'Kênh chung: ${selectedBuilding?.name ?? "Tòa nhà"}'
                            : 'Nhắn riêng: $_chatTargetName',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _chatTarget == 'group' ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _chatTarget == 'group'
                            ? 'Tin nhắn được gửi đến tất cả cư dân trong tòa nhà'
                            : 'Chỉ bạn và người này có thể đọc tin nhắn riêng tư',
                        style: TextStyle(
                          fontSize: 10,
                          color: _chatTarget == 'group' ? const Color(0xFF3B82F6) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_chatTarget != 'group')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _chatTarget = 'group';
                        _chatTargetName = 'Kênh chung';
                      });
                      _loadMessages();
                    },
                    icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFB45309)),
                    label: const Text(
                      'Về kênh chung',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),

          // 4. Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _chatTarget == 'group' ? Icons.forum_outlined : Icons.mark_chat_unread_outlined,
                              size: 48,
                              color: const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _chatTarget == 'group'
                                  ? 'Chưa có tin nhắn nào trong tòa nhà.'
                                  : 'Chưa có tin nhắn riêng với $_chatTargetName.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Hãy gửi tin nhắn đầu tiên để bắt đầu!',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == user?.id;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // 5. Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: _chatTarget == 'group'
                            ? 'Nhập tin nhắn chung...'
                            : 'Nhắn riêng cho $_chatTargetName...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    final isOwnerSender = msg.senderRole == 'OWNER' || msg.senderRole == 'SUPERADMIN';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.senderName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                if (msg.senderRole != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isOwnerSender ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isOwnerSender ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      isOwnerSender ? 'CHỦ NHÀ' : 'CƯ DÂN',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: isOwnerSender ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],
          GestureDetector(
            onLongPress: (isMe && !msg.isRecalled) ? () => _handleRecall(msg) : null,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isRecalled
                    ? const Color(0xFFF1F5F9)
                    : (isMe ? const Color(0xFF2563EB) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: (msg.isRecalled || !isMe) ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: msg.isRecalled
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'Tin nhắn đã bị thu hồi',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      msg.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            Formatters.formatTimeAgo(msg.createdAt),
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
