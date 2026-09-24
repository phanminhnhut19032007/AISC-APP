import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/building_model.dart';
import '../models/room_model.dart';
import '../models/invoice_model.dart';
import '../models/ticket_model.dart';
import '../models/notification_model.dart';
import '../models/unipack_model.dart';
import '../models/user_model.dart';
import '../models/emergency_alert_model.dart';
import '../services/building_service.dart';
import '../services/invoice_service.dart';
import '../services/ticket_service.dart';
import '../services/unipack_service.dart';
import '../services/emergency_service.dart';

class AppDataProvider with ChangeNotifier {
  final BuildingService _buildingService = BuildingService();
  final InvoiceService _invoiceService = InvoiceService();
  final TicketService _ticketService = TicketService();
  final UniPackService _uniPackService = UniPackService();
  final EmergencyService _emergencyService = EmergencyService();

  List<BuildingModel> _buildings = [];
  BuildingModel? _selectedBuilding;
  List<RoomModel> _rooms = [];
  List<RoomModel> _allRooms = [];
  List<InvoiceModel> _invoices = [];
  List<TicketModel> _tickets = [];
  List<AppNotificationModel> _notifications = [];
  List<UniPackOrder> _orders = [];
  final List<UniPackCartItem> _cart = [];
  List<EmergencyAlertModel> _emergencyAlerts = [];
  EmergencyAlertModel? _activeEmergencyModal;
  Timer? _emergencyPollingTimer;
  bool _isPollingEmergency = false;

  bool _isLoading = false;
  String? _errorMessage;
  bool _showDeletedInvoices = false;
  bool _showDeletedBuildings = false;

  // Getters
  List<BuildingModel> get buildings => _buildings;
  BuildingModel? get selectedBuilding => _selectedBuilding;
  List<RoomModel> get rooms => _rooms;
  List<RoomModel> get allRooms => _allRooms;
  List<InvoiceModel> get invoices => _invoices;
  List<TicketModel> get tickets => _tickets;
  List<AppNotificationModel> get notifications => _notifications;
  List<UniPackOrder> get orders => _orders;
  List<UniPackCartItem> get cart => _cart;
  List<EmergencyAlertModel> get emergencyAlerts => _emergencyAlerts;
  EmergencyAlertModel? get activeEmergencyModal => _activeEmergencyModal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showDeletedInvoices => _showDeletedInvoices;
  bool get showDeletedBuildings => _showDeletedBuildings;

  int get unreadEmergencyCount => _emergencyAlerts.where((a) => a.isActive).length;

  int get unreadNotifCount => _notifications.where((n) => !n.isRead).length;

  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  // KPIs
  int get totalRooms => _rooms.length;
  int get rentedRooms => _rooms.where((r) => r.isRented).length;
  int get availableRooms => _rooms.where((r) => r.isAvailable).length;
  int get maintenanceRooms => _rooms.where((r) => r.isMaintenance).length;

  double get monthlyRevenue => _invoices
      .where((inv) => inv.isPaid)
      .fold(0.0, (sum, inv) => sum + inv.totalAmount);

  int get pendingInvoicesCount => _invoices.where((inv) => inv.isPending || inv.isOverdue).length;
  int get openTicketsCount => _tickets.where((t) => t.status == 'OPEN' || t.status == 'IN_PROGRESS').length;

  Future<void> refreshAll(UserModel? currentUser, {String? roomCode}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await fetchBuildings();
      await fetchInvoices();
      await fetchTickets();
      await fetchOrders();
      await fetchNotifications(currentUser, roomCode: roomCode);
      await loadEmergencyAlerts();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBuildings({bool? includeDeleted}) async {
    final useDeleted = includeDeleted ?? _showDeletedBuildings;
    _buildings = await _buildingService.getBuildings(includeDeleted: useDeleted);

    // Load all rooms across all buildings for cross-reference in invoices & tickets
    final List<RoomModel> allRoomsList = [];
    for (final b in _buildings) {
      try {
        final r = await _buildingService.getRoomsByBuilding(b.id);
        allRoomsList.addAll(r);
      } catch (_) {}
    }
    _allRooms = allRoomsList;

    if (_buildings.isNotEmpty) {
      if (_selectedBuilding == null || !_buildings.any((b) => b.id == _selectedBuilding!.id)) {
        _selectedBuilding = _buildings.first;
      }
      await fetchRoomsForSelectedBuilding();
    } else {
      _selectedBuilding = null;
      _rooms = [];
    }
    notifyListeners();
  }

  void reset() {
    stopEmergencyPolling();
    _buildings = [];
    _selectedBuilding = null;
    _rooms = [];
    _allRooms = [];
    _invoices = [];
    _tickets = [];
    _orders = [];
    _cart.clear();
    _emergencyAlerts = [];
    _notifications = [];
    _activeEmergencyModal = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setShowDeletedBuildings(bool value) {
    _showDeletedBuildings = value;
    fetchBuildings(includeDeleted: value);
  }

  void setSelectedBuilding(BuildingModel building) {
    _selectedBuilding = building;
    notifyListeners();
    fetchRoomsForSelectedBuilding();
  }

  Future<void> fetchRoomsForSelectedBuilding() async {
    if (_selectedBuilding == null) return;
    _rooms = await _buildingService.getRoomsByBuilding(_selectedBuilding!.id);
    _rooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
    notifyListeners();
  }

  Future<void> createBuilding({
    required String name,
    required String address,
    required String province,
    required int totalFloors,
    int? autoGenerateRooms,
    double defaultRent = 3000000,
  }) async {
    final building = await _buildingService.createBuilding(
      name: name,
      address: address,
      province: province,
      totalFloors: totalFloors,
      autoGenerateRooms: autoGenerateRooms,
      defaultRent: defaultRent,
    );
    _buildings.add(building);
    setSelectedBuilding(building);
    await fetchBuildings();
  }

  Future<void> deleteBuilding(String id) async {
    await _buildingService.deleteBuilding(id);
    await fetchBuildings();
  }

  Future<void> restoreBuilding(String id) async {
    await _buildingService.restoreBuilding(id);
    await fetchBuildings();
  }

  Future<void> createRoom({
    required String roomNumber,
    required int floor,
    required double baseRent,
    double electricityRate = 4000,
    double waterRate = 25000,
    double internetFee = 100000,
    double parkingFee = 0,
    String status = 'AVAILABLE',
  }) async {
    if (_selectedBuilding == null) return;
    await _buildingService.createRoom(
      buildingId: _selectedBuilding!.id,
      roomNumber: roomNumber,
      floor: floor,
      baseRent: baseRent,
      electricityRate: electricityRate,
      waterRate: waterRate,
      internetFee: internetFee,
      parkingFee: parkingFee,
      status: status,
    );
    await fetchRoomsForSelectedBuilding();
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    await _buildingService.updateRoom(roomId, data);
    await fetchRoomsForSelectedBuilding();
  }

  Future<void> deleteRoom(String roomId) async {
    await _buildingService.deleteRoom(roomId);
    await fetchRoomsForSelectedBuilding();
  }

  Future<void> recordMeterReading({
    required String roomId,
    required String meterType,
    required double readingValue,
    required int month,
    required int year,
  }) async {
    await _buildingService.recordMeterReading(
      roomId: roomId,
      meterType: meterType,
      readingValue: readingValue,
      month: month,
      year: year,
    );
  }

  Future<void> fetchInvoices({int? month, int? year, bool? includeDeleted}) async {
    final useDeleted = includeDeleted ?? _showDeletedInvoices;
    _invoices = await _invoiceService.getInvoices(
      month: month,
      year: year,
      includeDeleted: useDeleted,
    );

    // Cross-reference roomNumber and buildingName from all loaded rooms & buildings
    for (final inv in _invoices) {
      final r = _allRooms.where((room) => room.id == inv.roomId).firstOrNull ??
          _rooms.where((room) => room.id == inv.roomId).firstOrNull;
      if (r != null) {
        inv.roomNumber = r.roomNumber;
        final b = _buildings.where((bld) => bld.id == r.buildingId).firstOrNull;
        if (b != null) {
          inv.buildingName = b.name;
        }
      }
    }

    _invoices.sort((a, b) => (b.year * 12 + b.month).compareTo(a.year * 12 + a.month));
    notifyListeners();
  }

  void setShowDeletedInvoices(bool value) {
    _showDeletedInvoices = value;
    fetchInvoices(includeDeleted: value);
  }

  Future<List<dynamic>> getMeterReadingsForRoom(String roomId) async {
    return await _invoiceService.getMeterReadingsByRoom(roomId);
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
    await _invoiceService.generateInvoiceForRoom(
      roomId: roomId,
      month: month,
      year: year,
      elecNew: elecNew,
      waterNew: waterNew,
      elecProofUrl: elecProofUrl,
      waterProofUrl: waterProofUrl,
    );
    await fetchInvoices();
  }

  Future<void> generateInvoices({
    required int month,
    required int year,
    double defaultElectricityRate = 4000,
    double defaultWaterRate = 25000,
  }) async {
    await _invoiceService.generateInvoices(
      month: month,
      year: year,
      buildingId: _selectedBuilding?.id,
      defaultElectricityRate: defaultElectricityRate,
      defaultWaterRate: defaultWaterRate,
    );
    await fetchInvoices(month: month, year: year);
  }

  Future<void> markInvoicePaid(String invoiceId) async {
    await _invoiceService.markPaid(invoiceId);
    await fetchInvoices();
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _invoiceService.deleteInvoice(invoiceId);
    await fetchInvoices();
  }

  Future<void> restoreInvoice(String invoiceId) async {
    await _invoiceService.restoreInvoice(invoiceId);
    await fetchInvoices();
  }

  Future<void> fetchTickets({String? status}) async {
    _tickets = await _ticketService.getTickets(status: status);

    // Cross-reference roomNumber and buildingName for tickets
    for (final t in _tickets) {
      final r = _allRooms.where((room) => room.id == t.roomId).firstOrNull ??
          _rooms.where((room) => room.id == t.roomId).firstOrNull;
      if (r != null) {
        t.roomNumber = r.roomNumber;
        final b = _buildings.where((bld) => bld.id == r.buildingId).firstOrNull;
        if (b != null) {
          t.buildingName = b.name;
        }
      }
    }

    notifyListeners();
  }

  Future<void> createTicket({
    required String roomId,
    required String title,
    required String description,
    String priority = 'MEDIUM',
    List<String> imageUrls = const [],
  }) async {
    await _ticketService.createTicket(
      roomId: roomId,
      title: title,
      description: description,
      priority: priority,
      imageUrls: imageUrls,
    );
    await fetchTickets();
  }

  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
    String? resolutionNote,
  }) async {
    await _ticketService.updateStatus(
      ticketId: ticketId,
      status: status,
      resolutionNote: resolutionNote,
    );
    await fetchTickets();
  }

  Future<void> rateTicket({
    required String ticketId,
    required int score,
    String? comment,
  }) async {
    await _ticketService.rateTicket(
      ticketId: ticketId,
      score: score,
      comment: comment,
    );
    await fetchTickets();
  }

  Future<void> fetchOrders() async {
    _orders = await _uniPackService.getOrders();
    notifyListeners();
  }

  Future<void> placeUniPackOrder({
    required String roomNumber,
    String receiverName = '',
    String receiverPhone = '',
    String paymentMethod = 'COD',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deadline = now + 60 * 60 * 1000; // 1 hour cancel window
    final orderDateStr = DateFormat('HH:mm:ss dd/MM/yyyy').format(DateTime.now());

    for (final item in _cart) {
      final randId = 'UP${100000 + Random().nextInt(900000)}';
      final order = UniPackOrder(
        id: randId,
        productName: item.product.name,
        roomNumber: roomNumber,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        quantity: item.quantity,
        totalPrice: item.totalPrice,
        paymentMethod: paymentMethod,
        status: 'PENDING_SUNDAY_DELIVERY',
        isPaid: false,
        createdAt: now,
        cancelDeadline: deadline,
        orderDate: orderDateStr,
      );
      await _uniPackService.saveOrder(order);
    }
    _cart.clear();
    await fetchOrders();
    notifyListeners();
  }

  Future<void> toggleOrderPayment(String orderId) async {
    await _uniPackService.togglePaymentStatus(orderId);
    await fetchOrders();
    notifyListeners();
  }

  Future<bool> cancelUniPackOrder(String orderId) async {
    final success = await _uniPackService.cancelOrder(orderId);
    if (success) {
      await fetchOrders();
      notifyListeners();
    }
    return success;
  }

  void addToCart(UniPackProduct product, {int quantity = 1}) {
    final idx = _cart.indexWhere((item) => item.product.id == product.id);
    if (idx >= 0) {
      _cart[idx].quantity += quantity;
    } else {
      _cart.add(UniPackCartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateCartQuantity(String productId, int delta) {
    final idx = _cart.indexWhere((item) => item.product.id == productId);
    if (idx >= 0) {
      _cart[idx].quantity += delta;
      if (_cart[idx].quantity <= 0) {
        _cart.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  Future<void> fetchNotifications(UserModel? user, {String? roomCode}) async {
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final readJson = prefs.getString(ApiConstants.readNotifIdsKey);
      final List<String> readIds = readJson != null ? List<String>.from(jsonDecode(readJson)) : [];

      final List<AppNotificationModel> list = [];

      if (user.isOwner) {
        // Tickets notifications for owner
        for (final t in _tickets.where((t) => t.status == 'OPEN')) {
          final id = 'ticket_open_${t.id}';
          list.add(AppNotificationModel(
            id: id,
            title: 'Yêu cầu sửa chữa mới',
            content: 'Phòng #${t.roomNumber ?? "cư dân"} vừa báo sự cố: "${t.title}"',
            type: 'TICKET',
            targetUrl: '/tickets',
            isRead: readIds.contains(id),
            createdAt: t.createdAt ?? DateTime.now().toIso8601String(),
          ));
        }

        // UniPack orders notifications for owner
        for (final o in _orders.where((o) => o.status == 'PENDING' || o.status == 'PENDING_SUNDAY_DELIVERY')) {
          final id = 'order_${o.id}';
          list.add(AppNotificationModel(
            id: id,
            title: 'Đơn hàng UniPack mới',
            content: 'Phòng ${o.roomNumber} đặt hàng: "${o.productName}"',
            type: 'ORDER',
            targetUrl: '/unipack',
            isRead: readIds.contains(id),
            createdAt: o.orderDate.isNotEmpty
                ? o.orderDate
                : DateTime.fromMillisecondsSinceEpoch(o.createdAt).toIso8601String(),
          ));
        }
      } else {
        // Tenant notifications
        for (final inv in _invoices.where((i) => i.isPending || i.isOverdue)) {
          final id = 'invoice_${inv.id}_pending';
          list.add(AppNotificationModel(
            id: id,
            title: 'Hóa đơn tiền phòng mới',
            content: 'Hóa đơn tháng ${inv.month}/${inv.year} đã được xuất. Số tiền: ${inv.totalAmount.toStringAsFixed(0)} đ',
            type: 'INVOICE',
            targetUrl: '/invoices',
            isRead: readIds.contains(id),
            createdAt: inv.dueDate ?? DateTime.now().toIso8601String(),
          ));
        }

        for (final t in _tickets) {
          final id = 'ticket_status_${t.id}_${t.status}';
          final statusName = t.status == 'CLOSED' ? 'Đã giải quyết' : (t.status == 'IN_PROGRESS' ? 'Đang sửa chữa' : 'Đã tiếp nhận');
          list.add(AppNotificationModel(
            id: id,
            title: 'Cập nhật tiến độ sự cố',
            content: 'Sự cố "${t.title}" của bạn đã đổi sang: $statusName',
            type: 'TICKET',
            targetUrl: '/tickets',
            isRead: readIds.contains(id),
            createdAt: t.createdAt ?? DateTime.now().toIso8601String(),
          ));
        }
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readJson = prefs.getString(ApiConstants.readNotifIdsKey);
    final List<String> readIds = readJson != null ? List<String>.from(jsonDecode(readJson)) : [];
    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setString(ApiConstants.readNotifIdsKey, jsonEncode(readIds));
    }
    for (var n in _notifications) {
      if (n.id == id) n.isRead = true;
    }
    notifyListeners();
  }

  Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> readIds = _notifications.map((n) => n.id).toList();
    await prefs.setString(ApiConstants.readNotifIdsKey, jsonEncode(readIds));
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  // Emergency SOS Methods (Real-time Live API & Web Sync)
  void startEmergencyPolling() {
    _emergencyPollingTimer?.cancel();
    // Poll every 3.5 seconds matching web's 4s interval for instant sync
    _emergencyPollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      checkActiveEmergencyLive();
    });
    checkActiveEmergencyLive();
  }

  void stopEmergencyPolling() {
    _emergencyPollingTimer?.cancel();
    _emergencyPollingTimer = null;
  }

  Future<void> checkActiveEmergencyLive() async {
    if (_isPollingEmergency) return;
    _isPollingEmergency = true;

    try {
      final activeList = await _emergencyService.getActiveEmergencies();

      if (activeList.isNotEmpty) {
        final newestAlert = activeList.first;
        // If there is a new active emergency and modal is not displaying it yet
        if (_activeEmergencyModal?.id != newestAlert.id) {
          _activeEmergencyModal = newestAlert;
          HapticFeedback.heavyImpact();
          await loadEmergencyAlerts();
        }
      } else {
        // No active emergencies on server (e.g. was resolved or acknowledged)
        if (_activeEmergencyModal != null) {
          _activeEmergencyModal = null;
          await loadEmergencyAlerts();
        }
      }
    } catch (_) {
    } finally {
      _isPollingEmergency = false;
    }
  }

  static List<EmergencyAlertModel> get defaultDemoAlerts => [
        EmergencyAlertModel(
          id: 'demo_alert_1',
          roomCode: '101',
          senderName: 'Trần Thị Mai',
          senderPhone: '0912345001',
          emergencyType: 'FIRE',
          note: 'Có khói bốc lên gần ban công',
          status: 'ACKNOWLEDGED',
          acknowledgedBy: 'Nguyễn Văn Chủ Trọ',
          timestamp: DateTime(2026, 9, 11, 17, 14, 33),
        ),
        EmergencyAlertModel(
          id: 'demo_alert_2',
          roomCode: '101',
          senderName: 'Trần Thị Mai',
          senderPhone: '0912345001',
          emergencyType: 'GAS_LEAK',
          note: 'Mùi gas nồng nặc ở khu vực bếp',
          status: 'RESOLVED',
          acknowledgedBy: 'Nguyễn Văn Chủ Trọ',
          timestamp: DateTime(2026, 9, 9, 21, 14, 33),
        ),
        EmergencyAlertModel(
          id: 'demo_alert_3',
          roomCode: '201',
          senderName: 'Lê Văn Nam',
          senderPhone: '0912345002',
          emergencyType: 'ELEVATOR',
          note: 'Thang máy tầng 2 bị kẹt cửa',
          status: 'RESOLVED',
          acknowledgedBy: 'Nguyễn Văn Chủ Trọ',
          timestamp: DateTime(2026, 9, 6, 21, 14, 33),
        ),
      ];

  Future<void> loadEmergencyAlerts() async {
    try {
      // 1. Fetch from live API
      List<EmergencyAlertModel> apiAlerts = [];
      try {
        apiAlerts = await _emergencyService.getEmergencyHistory();
      } catch (_) {}

      // 2. Fetch from local cache
      List<EmergencyAlertModel> localAlerts = [];
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString('emergency_sos_alerts');
      if (alertsJson != null) {
        try {
          final List list = jsonDecode(alertsJson);
          localAlerts = list.map((item) => EmergencyAlertModel.fromJson(item)).toList();
        } catch (_) {}
      }

      // 3. 3-Way Merge exactly matching Web logic: DEFAULT_DEMO_ALERTS + serverAlerts + localAlerts
      final map = <String, EmergencyAlertModel>{};
      for (final a in defaultDemoAlerts) {
        map[a.id] = a;
      }
      for (final a in localAlerts) {
        map[a.id] = a;
      }
      for (final a in apiAlerts) {
        map[a.id] = a;
      }

      final merged = map.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _emergencyAlerts = merged;

      // Save merged list back to local storage
      await prefs.setString(
        'emergency_sos_alerts',
        jsonEncode(_emergencyAlerts.map((e) => e.toJson()).toList()),
      );

      // 4. Fetch active emergencies for Owner popup alert
      try {
        final activeList = await _emergencyService.getActiveEmergencies();
        if (activeList.isNotEmpty) {
          _activeEmergencyModal = activeList.first;
        } else {
          _activeEmergencyModal = null;
        }
      } catch (_) {}

      notifyListeners();
    } catch (_) {
      try {
        final map = <String, EmergencyAlertModel>{};
        for (final a in defaultDemoAlerts) {
          map[a.id] = a;
        }
        final prefs = await SharedPreferences.getInstance();
        final alertsJson = prefs.getString('emergency_sos_alerts');
        if (alertsJson != null) {
          final List list = jsonDecode(alertsJson);
          for (final item in list) {
            final a = EmergencyAlertModel.fromJson(item);
            map[a.id] = a;
          }
        }
        _emergencyAlerts = map.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> sendEmergencyAlert({
    required String senderName,
    required String roomCode,
    String? buildingName,
    String emergencyType = 'OTHER',
    String? note,
  }) async {
    EmergencyAlertModel? createdAlert;

    // 1. Send live SOS request directly to /api/v1/emergency/sos
    try {
      createdAlert = await _emergencyService.triggerSos(
        roomNumber: roomCode,
        buildingName: buildingName ?? selectedBuilding?.name ?? 'Tòa nhà REASY',
        emergencyType: emergencyType,
        description: note,
      );
    } catch (_) {
      // Create local fallback model if offline
      createdAlert = EmergencyAlertModel(
        id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
        senderName: senderName,
        roomCode: roomCode,
        buildingName: buildingName ?? selectedBuilding?.name ?? 'Tòa nhà REASY',
        emergencyType: emergencyType,
        note: note?.trim().isNotEmpty == true ? note!.trim() : null,
        timestamp: DateTime.now(),
        status: 'ACTIVE',
      );
    }

    _emergencyAlerts.insert(0, createdAlert);
    _activeEmergencyModal = createdAlert;

    // Save to SharedPreferences for instant caching
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_sos_alerts', jsonEncode(_emergencyAlerts.map((e) => e.toJson()).toList()));
    notifyListeners();

    // 2. Also create an URGENT Ticket so tickets system on Web also receives it
    try {
      final targetRoom = _rooms.firstWhere(
        (r) => r.roomNumber.toString() == roomCode.toString(),
        orElse: () => _rooms.isNotEmpty ? _rooms.first : RoomModel(id: '', buildingId: '', roomNumber: roomCode, baseRent: 0, status: 'OCCUPIED'),
      );

      if (targetRoom.id.isNotEmpty) {
        await _ticketService.createTicket(
          roomId: targetRoom.id,
          title: '🚨 [BÁO ĐỘNG KHẨN CẤP - SOS] Phòng #$roomCode',
          description: note?.trim().isNotEmpty == true
              ? 'Tín hiệu phát SOS từ $senderName tại phòng #$roomCode. Nội dung: $note'
              : 'Tín hiệu phát SOS khẩn cấp từ $senderName tại phòng #$roomCode!',
          priority: 'URGENT',
        );
        await fetchTickets();
      }
    } catch (_) {}
  }

  Future<void> acknowledgeEmergencyAlert(String alertId) async {
    // 1. Call live API endpoint /api/v1/emergency/{alert_id}/acknowledge
    try {
      await _emergencyService.acknowledgeEmergency(alertId);
    } catch (_) {}

    for (var alert in _emergencyAlerts) {
      if (alert.id == alertId) {
        alert.status = 'ACKNOWLEDGED';
        alert.acknowledgedBy ??= 'Nguyễn Văn Chủ Trọ';
      }
    }
    if (_activeEmergencyModal?.id == alertId) {
      _activeEmergencyModal = null;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_sos_alerts', jsonEncode(_emergencyAlerts.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> resolveEmergencyAlert(String alertId) async {
    // 1. Call live API endpoint /api/v1/emergency/{alert_id}/resolve
    try {
      await _emergencyService.resolveEmergency(alertId);
    } catch (_) {}

    for (var alert in _emergencyAlerts) {
      if (alert.id == alertId) {
        alert.status = 'RESOLVED';
      }
    }
    if (_activeEmergencyModal?.id == alertId) {
      _activeEmergencyModal = null;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_sos_alerts', jsonEncode(_emergencyAlerts.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void dismissActiveEmergencyModal() {
    _activeEmergencyModal = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopEmergencyPolling();
    super.dispose();
  }
}
