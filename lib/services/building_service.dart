import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/building_model.dart';
import '../models/room_model.dart';

class BuildingService {
  final ApiClient _api = ApiClient();

  Future<List<BuildingModel>> getBuildings({bool includeDeleted = false}) async {
    final Map<String, dynamic> params = {};
    if (includeDeleted) params['include_deleted'] = true;
    final response = await _api.get(ApiConstants.buildings, queryParameters: params);
    final List list = response.data is List ? response.data : [];
    return list.map((item) => BuildingModel.fromJson(item)).toList();
  }

  Future<BuildingModel> createBuilding({
    required String name,
    required String address,
    required String province,
    required int totalFloors,
    int? autoGenerateRooms,
    double defaultRent = 3000000,
  }) async {
    final response = await _api.post(
      ApiConstants.buildings,
      data: {
        'name': name,
        'address': address,
        'province': province,
        'total_floors': totalFloors,
      },
    );
    final building = BuildingModel.fromJson(response.data);

    // If auto-generate rooms requested (like on Web)
    if (autoGenerateRooms != null && autoGenerateRooms > 0) {
      final int roomsPerFloor = (autoGenerateRooms / totalFloors).ceil();
      int roomIndex = 0;
      for (int floor = 1; floor <= totalFloors; floor++) {
        for (int r = 1; r <= roomsPerFloor; r++) {
          if (roomIndex >= autoGenerateRooms) break;
          final roomNum = '${floor}0$r';
          try {
            await createRoom(
              buildingId: building.id,
              roomNumber: roomNum,
              floor: floor,
              baseRent: defaultRent,
            );
          } catch (_) {}
          roomIndex++;
        }
      }
    }

    return building;
  }

  Future<void> deleteBuilding(String id) async {
    await _api.delete('${ApiConstants.buildings}/$id');
  }

  Future<void> restoreBuilding(String id) async {
    await _api.post('${ApiConstants.buildings}/$id/restore');
  }

  Future<List<RoomModel>> getRoomsByBuilding(String buildingId) async {
    final response = await _api.get('${ApiConstants.buildings}/$buildingId/rooms');
    final List list = response.data is List ? response.data : [];
    return list.map((item) => RoomModel.fromJson(item)).toList();
  }

  Future<RoomModel> createRoom({
    required String buildingId,
    required String roomNumber,
    required int floor,
    required double baseRent,
    double electricityRate = 4000,
    double waterRate = 25000,
    double internetFee = 100000,
    double parkingFee = 0,
    String status = 'AVAILABLE',
  }) async {
    final response = await _api.post(
      ApiConstants.rooms,
      data: {
        'building_id': buildingId,
        'room_number': roomNumber,
        'floor': floor,
        'base_rent': baseRent,
        'electricity_rate': electricityRate,
        'water_rate': waterRate,
        'internet_fee': internetFee,
        'parking_fee': parkingFee,
        'status': status,
      },
    );
    return RoomModel.fromJson(response.data);
  }

  Future<RoomModel> updateRoom(String roomId, Map<String, dynamic> data) async {
    final response = await _api.patch('${ApiConstants.rooms}/$roomId', data: data);
    return RoomModel.fromJson(response.data);
  }

  Future<void> deleteRoom(String roomId) async {
    await _api.delete('${ApiConstants.rooms}/$roomId');
  }

  Future<void> recordMeterReading({
    required String roomId,
    required String meterType, // ELECTRICITY, WATER
    required double readingValue,
    required int month,
    required int year,
  }) async {
    await _api.post(
      ApiConstants.meterReadings,
      data: {
        'room_id': roomId,
        'meter_type': meterType,
        'new_reading': readingValue,
        'month': month,
        'year': year,
        'is_manual': true,
      },
    );
  }
}
