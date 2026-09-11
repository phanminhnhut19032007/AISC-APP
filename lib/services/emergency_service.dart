import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/emergency_alert_model.dart';

class EmergencyService {
  final ApiClient _api = ApiClient();

  Future<EmergencyAlertModel> triggerSos({
    required String roomNumber,
    String? buildingName,
    String emergencyType = 'OTHER',
    String? description,
  }) async {
    final response = await _api.post(
      ApiConstants.emergencySos,
      data: {
        'room_number': roomNumber,
        'building_name': buildingName ?? 'Tòa nhà REASY',
        'emergency_type': emergencyType,
        'description': description,
      },
    );
    return EmergencyAlertModel.fromJson(response.data);
  }

  Future<List<EmergencyAlertModel>> getActiveEmergencies() async {
    final response = await _api.get(ApiConstants.emergencyActive);
    final List list = response.data is List ? response.data : [];
    return list.map((item) => EmergencyAlertModel.fromJson(item)).toList();
  }

  Future<List<EmergencyAlertModel>> getEmergencyHistory() async {
    final response = await _api.get(ApiConstants.emergencyList);
    final List list = response.data is List ? response.data : [];
    return list.map((item) => EmergencyAlertModel.fromJson(item)).toList();
  }

  Future<void> acknowledgeEmergency(String alertId) async {
    await _api.post(ApiConstants.emergencyAcknowledge(alertId));
  }

  Future<void> resolveEmergency(String alertId) async {
    await _api.post(ApiConstants.emergencyResolve(alertId));
  }
}
