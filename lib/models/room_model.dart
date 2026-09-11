class RoomModel {
  final String id;
  final String buildingId;
  final String roomNumber;
  final int floor;
  final double? areaSqm;
  final double baseRent;
  final double electricityRate;
  final double waterRate;
  final double internetFee;
  final double parkingFee;
  final String status; // AVAILABLE, RENTED, MAINTENANCE
  final String? thumbnailUrl;

  RoomModel({
    required this.id,
    required this.buildingId,
    required this.roomNumber,
    this.floor = 1,
    this.areaSqm,
    this.baseRent = 0,
    this.electricityRate = 4000,
    this.waterRate = 25000,
    this.internetFee = 100000,
    this.parkingFee = 0,
    this.status = 'AVAILABLE',
    this.thumbnailUrl,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      buildingId: json['building_id'] ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      floor: json['floor'] ?? 1,
      areaSqm: json['area_sqm'] != null ? (json['area_sqm'] as num).toDouble() : null,
      baseRent: json['base_rent'] != null ? (json['base_rent'] as num).toDouble() : 0,
      electricityRate: json['electricity_rate'] != null ? (json['electricity_rate'] as num).toDouble() : 4000,
      waterRate: json['water_rate'] != null ? (json['water_rate'] as num).toDouble() : 25000,
      internetFee: json['internet_fee'] != null ? (json['internet_fee'] as num).toDouble() : 100000,
      parkingFee: json['parking_fee'] != null ? (json['parking_fee'] as num).toDouble() : 0,
      status: json['status'] ?? 'AVAILABLE',
      thumbnailUrl: json['thumbnail_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'building_id': buildingId,
      'room_number': roomNumber,
      'floor': floor,
      'area_sqm': areaSqm,
      'base_rent': baseRent,
      'electricity_rate': electricityRate,
      'water_rate': waterRate,
      'internet_fee': internetFee,
      'parking_fee': parkingFee,
      'status': status,
      'thumbnail_url': thumbnailUrl,
    };
  }

  bool get isAvailable => status == 'AVAILABLE';
  bool get isRented => status == 'RENTED';
  bool get isMaintenance => status == 'MAINTENANCE';

  String get statusLabel {
    switch (status) {
      case 'AVAILABLE':
        return 'Còn trống';
      case 'RENTED':
        return 'Đang thuê';
      case 'MAINTENANCE':
        return 'Bảo trì';
      default:
        return status;
    }
  }
}
