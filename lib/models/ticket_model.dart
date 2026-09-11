class TicketModel {
  final String id;
  final String roomId;
  final String? tenantId;
  final String? technicianId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String status; // OPEN, ASSIGNED, IN_PROGRESS, CLOSED, CANCELLED
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final String? resolutionNote;
  final String? createdAt;

  // Attached UI helper fields
  String? roomNumber;
  String? tenantName;
  String? buildingName;

  TicketModel({
    required this.id,
    required this.roomId,
    this.tenantId,
    this.technicianId,
    required this.title,
    this.description = '',
    this.imageUrls = const [],
    this.status = 'OPEN',
    this.priority = 'MEDIUM',
    this.resolutionNote,
    this.createdAt,
    this.roomNumber,
    this.tenantName,
    this.buildingName,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      tenantId: json['tenant_id'],
      technicianId: json['technician_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : [],
      status: json['status'] ?? 'OPEN',
      priority: json['priority'] ?? 'MEDIUM',
      resolutionNote: json['resolution_note'],
      createdAt: json['created_at'],
      roomNumber: json['room_number']?.toString(),
      tenantName: json['tenant_name'],
      buildingName: json['building_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'tenant_id': tenantId,
      'technician_id': technicianId,
      'title': title,
      'description': description,
      'image_urls': imageUrls,
      'status': status,
      'priority': priority,
      'resolution_note': resolutionNote,
      'created_at': createdAt,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'OPEN':
        return 'Chờ tiếp nhận';
      case 'ASSIGNED':
        return 'Đã tiếp nhận';
      case 'IN_PROGRESS':
        return 'Đang sửa chữa';
      case 'CLOSED':
        return 'Đã giải quyết';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'URGENT':
        return 'Khẩn cấp';
      case 'HIGH':
        return 'Cao';
      case 'MEDIUM':
        return 'Trung bình';
      case 'LOW':
        return 'Thấp';
      default:
        return priority;
    }
  }
}
