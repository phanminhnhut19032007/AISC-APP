import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/unipack_model.dart';

class UniPackService {
  static final List<UniPackProduct> sampleProducts = [
    UniPackProduct(
      id: 'p1',
      name: 'Gói Sữa Tươi Tiết Kiệm Vinamilk',
      category: 'Đồ uống',
      packageSize: '12 lốc (48 hộp x 180ml)',
      description: 'Sữa tươi tiệt trùng Vinamilk 100% có đường, thơm ngon nhiều dinh dưỡng.',
      originalPrice: 384000,
      wholesalePrice: 295000,
      savePercent: 23,
      imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'p2',
      name: 'Gói Snack Khoai Tây Lay\'s Party',
      category: 'Snack & Bánh kẹo',
      packageSize: '20 bịch lớn (tự chọn vị)',
      description: 'Snack khoai tây Lays giòn rụm với các vị khoai tây tự nhiên, sườn nướng BBQ, tảo biển.',
      originalPrice: 220000,
      wholesalePrice: 155000,
      savePercent: 30,
      imageUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'p3',
      name: 'Gói Mỳ Tôm Hảo Hảo Tôm Chua Cay',
      category: 'Mỳ ăn liền',
      packageSize: '1 thùng sỉ (30 gói)',
      description: 'Mỳ ăn liền quốc dân Hảo Hảo hương vị Tôm Chua Cay chua thanh, cay nồng đậm đà.',
      originalPrice: 145000,
      wholesalePrice: 118000,
      savePercent: 19,
      imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'p4',
      name: 'Gói Nước Ngọt Coca-Cola Tiết Kiệm',
      category: 'Đồ uống',
      packageSize: '1 thùng (24 lon x 320ml)',
      description: 'Nước giải khát có ga Coca-Cola chính hãng mang lại cảm giác sảng khoái tức thì.',
      originalPrice: 240000,
      wholesalePrice: 185000,
      savePercent: 23,
      imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'p5',
      name: 'Gói Nước Khoáng Aquafina Tinh Khiết',
      category: 'Đồ uống',
      packageSize: '1 thùng (24 chai x 500ml)',
      description: 'Nước uống đóng chai Aquafina tinh khiết được lọc qua hệ thống tuần hoàn khép kín.',
      originalPrice: 120000,
      wholesalePrice: 89000,
      savePercent: 26,
      imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=500&auto=format&fit=crop&q=60',
    ),
  ];

  Future<List<UniPackOrder>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ApiConstants.unipackOrdersKey);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((item) => UniPackOrder.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrder(UniPackOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    orders.insert(0, order);
    final raw = jsonEncode(orders.map((o) => o.toJson()).toList());
    await prefs.setString(ApiConstants.unipackOrdersKey, raw);
  }

  Future<void> updateOrder(UniPackOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final updated = orders.map((o) => o.id == order.id ? order : o).toList();
    final raw = jsonEncode(updated.map((o) => o.toJson()).toList());
    await prefs.setString(ApiConstants.unipackOrdersKey, raw);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final updated = orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(status: newStatus);
      }
      return o;
    }).toList();
    final raw = jsonEncode(updated.map((o) => o.toJson()).toList());
    await prefs.setString(ApiConstants.unipackOrdersKey, raw);
  }

  Future<void> togglePaymentStatus(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final updated = orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(isPaid: !o.isPaid);
      }
      return o;
    }).toList();
    final raw = jsonEncode(updated.map((o) => o.toJson()).toList());
    await prefs.setString(ApiConstants.unipackOrdersKey, raw);
  }

  Future<bool> cancelOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final order = orders.where((o) => o.id == orderId).firstOrNull;
    if (order == null) return false;
    if (!order.isCanCancel) return false;

    final updated = orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(status: 'CANCELLED');
      }
      return o;
    }).toList();
    final raw = jsonEncode(updated.map((o) => o.toJson()).toList());
    await prefs.setString(ApiConstants.unipackOrdersKey, raw);
    return true;
  }
}
