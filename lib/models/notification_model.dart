class AppNotificationModel {
  final String id;
  final String title;
  final String content;
  final String type; // TICKET, INVOICE, ORDER, CHAT, GENERAL
  final String targetUrl;
  final String createdAt;
  bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.targetUrl,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'GENERAL',
      targetUrl: json['targetUrl'] ?? json['target_url'] ?? '',
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'targetUrl': targetUrl,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}
