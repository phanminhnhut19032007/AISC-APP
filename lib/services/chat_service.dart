import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final ApiClient _api = ApiClient();

  Future<List<ChatMessageModel>> getMessages(String buildingId, {String? recipientId}) async {
    final Map<String, dynamic> params = {};
    if (recipientId != null) params['recipient_id'] = recipientId;

    final response = await _api.get(
      ApiConstants.chatMessages(buildingId),
      queryParameters: params,
    );
    final List list = response.data is List ? response.data : [];
    return list.map((item) => ChatMessageModel.fromJson(item)).toList();
  }

  Future<ChatMessageModel> sendMessage({
    required String buildingId,
    required String message,
    String? recipientId,
  }) async {
    final response = await _api.post(
      ApiConstants.chatMessages(buildingId),
      data: {
        'message': message,
        if (recipientId != null) 'recipient_id': recipientId,
      },
    );
    return ChatMessageModel.fromJson(response.data);
  }

  Future<void> recallMessage(String buildingId, String messageId) async {
    await _api.delete('${ApiConstants.chatMessages(buildingId)}/$messageId');
  }

  Future<List<dynamic>> getMembers(String buildingId) async {
    final response = await _api.get(ApiConstants.chatMembers(buildingId));
    return response.data is List ? response.data : [];
  }
}
