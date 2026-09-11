import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final ApiClient _api = ApiClient();

  Future<List<InvoiceModel>> getInvoices({
    int? month,
    int? year,
    bool includeDeleted = false,
    String? roomId,
    String? status,
  }) async {
    final Map<String, dynamic> params = {};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    if (includeDeleted) params['include_deleted'] = true;
    if (roomId != null) params['room_id'] = roomId;
    if (status != null && status != 'ALL') params['status'] = status;

    final response = await _api.get(ApiConstants.invoices, queryParameters: params);
    final List list = response.data is List ? response.data : [];
    return list.map((item) => InvoiceModel.fromJson(item)).toList();
  }

  Future<List<dynamic>> getMeterReadingsByRoom(String roomId) async {
    final response = await _api.get('${ApiConstants.meterReadings}/room/$roomId');
    return response.data is List ? response.data : [];
  }

  Future<void> generateInvoiceForRoom({
    required String roomId,
    required int month,
    required int year,
    required double elecNew,
    required double waterNew,
    String? elecProofUrl,
    String? waterProofUrl,
  }) async {
    // 1. Lưu chỉ số điện
    await _api.post(
      ApiConstants.meterReadings,
      data: {
        'room_id': roomId,
        'meter_type': 'ELECTRICITY',
        'month': month,
        'year': year,
        'new_reading': elecNew,
        'is_manual': true,
        if (elecProofUrl != null) 'ocr_image_url': elecProofUrl,
      },
    );

    // 2. Lưu chỉ số nước
    await _api.post(
      ApiConstants.meterReadings,
      data: {
        'room_id': roomId,
        'meter_type': 'WATER',
        'month': month,
        'year': year,
        'new_reading': waterNew,
        'is_manual': true,
        if (waterProofUrl != null) 'ocr_image_url': waterProofUrl,
      },
    );

    // 3. Gọi tính và tạo hóa đơn
    await _api.post(
      ApiConstants.generateInvoices,
      data: {
        'room_id': roomId,
        'month': month,
        'year': year,
      },
    );
  }

  Future<void> generateInvoices({
    required int month,
    required int year,
    String? buildingId,
    double defaultElectricityRate = 4000,
    double defaultWaterRate = 25000,
  }) async {
    await _api.post(
      ApiConstants.generateInvoices,
      data: {
        'month': month,
        'year': year,
        if (buildingId != null) 'building_id': buildingId,
        'default_electricity_rate': defaultElectricityRate,
        'default_water_rate': defaultWaterRate,
      },
    );
  }

  Future<void> markPaid(String invoiceId) async {
    await _api.patch('${ApiConstants.invoices}/$invoiceId/mark-paid');
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _api.delete('${ApiConstants.invoices}/$invoiceId');
  }

  Future<void> restoreInvoice(String invoiceId) async {
    await _api.post('${ApiConstants.invoices}/$invoiceId/restore');
  }
}
