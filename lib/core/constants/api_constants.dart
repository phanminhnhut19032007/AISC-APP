class ApiConstants {
  static const String baseUrl = 'https://aisc-1.onrender.com/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String fcmToken = '/auth/fcm-token';

  // Emergency SOS
  static const String emergencySos = '/emergency/sos';
  static const String emergencyActive = '/emergency/active';
  static const String emergencyList = '/emergency/list';
  static String emergencyAcknowledge(String alertId) => '/emergency/$alertId/acknowledge';
  static String emergencyResolve(String alertId) => '/emergency/$alertId/resolve';

  // Buildings & Rooms
  static const String buildings = '/buildings';
  static const String rooms = '/rooms';
  static const String meterReadings = '/meter-readings';

  // Invoices
  static const String invoices = '/invoices';
  static const String generateInvoices = '/invoices/generate';

  // Tickets
  static const String tickets = '/tickets';

  // Chat
  static String chatMessages(String buildingId) => '/chat/$buildingId/messages';
  static String chatMembers(String buildingId) => '/chat/$buildingId/members';

  // Local storage keys
  static const String tokenKey = 'smartrent_token';
  static const String userKey = 'smartrent_user';
  static const String demoTenantRoomKey = 'demo_tenant_room_code';
  static const String readNotifIdsKey = 'renteasy_read_notif_ids';
  static const String unipackOrdersKey = 'unipack_orders';
  static const String unipackCartKey = 'unipack_cart';
}
