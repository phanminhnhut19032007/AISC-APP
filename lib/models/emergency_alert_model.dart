class EmergencyAlertModel {
  final String id;
  final String senderName;
  final String? senderPhone;
  final String roomCode;
  final String buildingName;
  final String emergencyType; // FIRE, THEFT, MEDICAL, GAS_LEAK, OTHER
  final String? note;
  final DateTime timestamp;
  String status; // ACTIVE, ACKNOWLEDGED, RESOLVED

  EmergencyAlertModel({
    required this.id,
    required this.senderName,
    this.senderPhone,
    required this.roomCode,
    this.buildingName = 'Tòa nhà REASY',
    this.emergencyType = 'OTHER',
    this.note,
    required this.timestamp,
    this.status = 'ACTIVE',
  });

  bool get isAcknowledged => status == 'ACKNOWLEDGED' || status == 'RESOLVED';
  bool get isActive => status == 'ACTIVE';

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_name': senderName,
        'sender_phone': senderPhone,
        'room_number': roomCode,
        'room_code': roomCode,
        'building_name': buildingName,
        'emergency_type': emergencyType,
        'description': note,
        'note': note,
        'status': status,
        'created_at': timestamp.toIso8601String(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return EmergencyAlertModel(
      id: json['id']?.toString() ?? '',
      senderName: json['sender_name'] ?? json['senderName'] ?? 'Cư dân',
      senderPhone: json['sender_phone'] ?? json['senderPhone'],
      roomCode: json['room_number']?.toString() ?? json['room_code']?.toString() ?? '101',
      buildingName: json['building_name'] ?? json['buildingName'] ?? 'Tòa nhà REASY',
      emergencyType: json['emergency_type']?.toString().toUpperCase() ?? 'OTHER',
      note: json['description'] ?? json['note'],
      timestamp: parseDate(json['created_at'] ?? json['timestamp']),
      status: json['status']?.toString().toUpperCase() ??
          (json['is_acknowledged'] == true ? 'ACKNOWLEDGED' : 'ACTIVE'),
    );
  }
}
