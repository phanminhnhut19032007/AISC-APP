class InvoiceModel {
  final String id;
  final String roomId;
  final int month;
  final int year;
  final double baseRent;
  final double electricityAmount;
  final double waterAmount;
  final double serviceFeesAmount;
  final double totalAmount;
  final String status; // DRAFT, SENT, PAID, OVERDUE, CANCELLED
  final String? dueDate;
  final String? paidAt;
  final String? vietqrCode;
  final String? paymentReference;
  final String? notes;
  final bool isDeleted;

  // Attached/computed fields for UI
  String? roomNumber;
  String? buildingName;

  InvoiceModel({
    required this.id,
    required this.roomId,
    required this.month,
    required this.year,
    this.baseRent = 0,
    this.electricityAmount = 0,
    this.waterAmount = 0,
    this.serviceFeesAmount = 0,
    this.totalAmount = 0,
    this.status = 'SENT',
    this.dueDate,
    this.paidAt,
    this.vietqrCode,
    this.paymentReference,
    this.notes,
    this.isDeleted = false,
    this.roomNumber,
    this.buildingName,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      baseRent: json['base_rent'] != null ? (json['base_rent'] as num).toDouble() : 0,
      electricityAmount: json['electricity_amount'] != null ? (json['electricity_amount'] as num).toDouble() : 0,
      waterAmount: json['water_amount'] != null ? (json['water_amount'] as num).toDouble() : 0,
      serviceFeesAmount: json['service_fees_amount'] != null ? (json['service_fees_amount'] as num).toDouble() : 0,
      totalAmount: json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : 0,
      status: json['status'] ?? 'SENT',
      dueDate: json['due_date'],
      paidAt: json['paid_at'],
      vietqrCode: json['vietqr_code'],
      paymentReference: json['payment_reference'],
      notes: json['notes'],
      isDeleted: json['is_deleted'] ?? false,
      roomNumber: json['room_number']?.toString(),
      buildingName: json['building_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'month': month,
      'year': year,
      'base_rent': baseRent,
      'electricity_amount': electricityAmount,
      'water_amount': waterAmount,
      'service_fees_amount': serviceFeesAmount,
      'total_amount': totalAmount,
      'status': status,
      'due_date': dueDate,
      'paid_at': paidAt,
      'vietqr_code': vietqrCode,
      'payment_reference': paymentReference,
      'notes': notes,
      'is_deleted': isDeleted,
    };
  }

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'SENT' || status == 'DRAFT';
  bool get isOverdue => status == 'OVERDUE';

  String get statusLabel {
    switch (status) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'SENT':
      case 'DRAFT':
        return 'Chưa thanh toán';
      case 'OVERDUE':
        return 'Quá hạn';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
