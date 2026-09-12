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

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-poll every 3 seconds for instant real-time sync with Web
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollNewMessages();
    });
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
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id;
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
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id;
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
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id;
    if (buildingId == null) return;

    _isBackgroundPolling = true;
    try {
      final recipientId = _chatTarget == 'group' ? null : _chatTarget;
      final list = await _chatService.getMessages(buildingId, recipientId: recipientId);
      if (mounted) {
        // Compare with current messages (new messages count, last message ID, or recall status)
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

    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id;
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
    final buildingId = context.read<AppDataProvider>().selectedBuilding?.id;
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const AppHeader(title: 'Chat nội bộ tòa nhà'),
      drawer: AppDrawer(
        currentIndex: (auth.currentUser?.isOwner ?? true) ? 5 : 4,
        onTabSelected: (idx) => widget.onNavigateTab?.call(idx),
      ),
      body: Column(
        children: [
          // Channel banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  _chatTarget == 'group' ? Icons.forum_rounded : Icons.person_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _chatTarget == 'group'
                        ? 'Kênh chung: ${data.selectedBuilding?.name ?? "Tòa nhà"}'
                        : 'Trò chuyện với: $_chatTargetName',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                  onPressed: _loadMessages,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Tải lại',
                ),
              ],
            ),
          ),

          // Members Selector Bar (Group vs DMs)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Group Chat Chip
                  ChoiceChip(
                    avatar: const Icon(Icons.group_rounded, size: 15),
                    label: const Text('Tất cả'),
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
                      side: BorderSide(color: _chatTarget == 'group' ? const Color(0xFF2563EB) : AppColors.borderLight),
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
                    final room = m['room_number'] as String? ?? (role == 'OWNER' ? 'Chủ trọ' : '');
                    final isSelected = _chatTarget == uid;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Icon(
                          role == 'OWNER' ? Icons.shield_rounded : Icons.person_outline_rounded,
                          size: 15,
                          color: isSelected ? Colors.white : (role == 'OWNER' ? const Color(0xFF2563EB) : AppColors.textSecondary),
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
                          side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : AppColors.borderLight),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          _chatTarget == 'group'
                              ? 'Chưa có tin nhắn nào trong tòa nhà.\nHãy gửi lời chào đầu tiên!'
                              : 'Chưa có tin nhắn riêng với $_chatTargetName.\nHãy bắt đầu cuộc trò chuyện!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
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

          // Input field
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
                            : 'Nhắn cho $_chatTargetName...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.bgLight,
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
                      color: AppColors.primary,
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
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: msg.senderRole == 'OWNER' ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      msg.senderRole == 'OWNER' ? 'Chủ trọ' : 'Cư dân',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: msg.senderRole == 'OWNER' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
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
                    : (isMe ? AppColors.primary : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: (msg.isRecalled || !isMe) ? Border.all(color: AppColors.borderLight) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
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
