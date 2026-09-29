class BuildingModel {
  final String id;
  final String? ownerId;
  final String name;
  final String address;
  final String? province;
  final int totalFloors;
  final String? description;
  final String? thumbnailUrl;
  final String buildingCode;
  final bool isDeleted;

  BuildingModel({
    required this.id,
    this.ownerId,
    required this.name,
    required this.address,
    this.province,
    this.totalFloors = 1,
    this.description,
    this.thumbnailUrl,
    this.buildingCode = 'MC892',
    this.isDeleted = false,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id'] ?? '',
      ownerId: json['owner_id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      province: json['province'],
      totalFloors: json['total_floors'] ?? 1,
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      buildingCode: json['building_code'] ?? json['code'] ?? 'MC892',
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'province': province,
      'total_floors': totalFloors,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'building_code': buildingCode,
      'is_deleted': isDeleted,
    };
  }
}
