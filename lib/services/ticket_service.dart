import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/ticket_model.dart';

class TicketService {
  final ApiClient _api = ApiClient();

  Future<List<TicketModel>> getTickets({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status'] = status;
    }

    final response = await _api.get(ApiConstants.tickets, queryParameters: params);
    final List list = response.data is List ? response.data : [];
    return list.map((item) => TicketModel.fromJson(item)).toList();
  }

  Future<TicketModel> createTicket({
    required String roomId,
    required String title,
    required String description,
    String priority = 'MEDIUM',
    List<String> imageUrls = const [],
  }) async {
    final response = await _api.post(
      ApiConstants.tickets,
      data: {
        'room_id': roomId,
        'title': title,
        'description': description,
        'priority': priority,
        'image_urls': imageUrls,
      },
    );
    return TicketModel.fromJson(response.data);
  }

  Future<void> updateStatus({
    required String ticketId,
    required String status,
    String? resolutionNote,
  }) async {
    await _api.patch(
      '${ApiConstants.tickets}/$ticketId/status',
      data: {
        'status': status,
        if (resolutionNote != null) 'resolution_note': resolutionNote,
      },
    );
  }

  Future<void> assignTechnician({
    required String ticketId,
    required String technicianId,
  }) async {
    await _api.patch(
      '${ApiConstants.tickets}/$ticketId/assign',
      data: {'technician_id': technicianId},
    );
  }

  Future<void> rateTicket({
    required String ticketId,
    required int score,
    String? comment,
  }) async {
    await _api.post(
      '${ApiConstants.tickets}/$ticketId/rating',
      data: {
        'score': score,
        if (comment != null) 'comment': comment,
      },
    );
  }
}
