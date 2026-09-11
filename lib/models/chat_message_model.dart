class ChatMessageModel {
  final String id;
  final String buildingId;
  final String senderId;
  final String senderName;
  final String? senderRole;
  final String? recipientId;
  final String? recipientName;
  final String message;
  final bool isRecalled;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.buildingId,
    required this.senderId,
    required this.senderName,
    this.senderRole,
    this.recipientId,
    this.recipientName,
    required this.message,
    this.isRecalled = false,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      buildingId: json['building_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? json['full_name'] ?? 'Cư dân',
      senderRole: json['sender_role'],
      recipientId: json['recipient_id'],
      recipientName: json['recipient_name'],
      message: json['message'] ?? '',
      isRecalled: json['is_recalled'] ?? false,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'building_id': buildingId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'message': message,
      'is_recalled': isRecalled,
      'created_at': createdAt,
    };
  }
}
