import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/unipack_model.dart';

class UniPackService {
  static final List<UniPackProduct> sampleProducts = [
    UniPackProduct(
      id: 'prod_vinamilk_1',
      name: 'Gói Sữa Tươi Tiết Kiệm Vinamilk',
      category: 'Đồ uống dinh dưỡng',
      packageSize: '12 lốc (48 hộp x 180ml)',
      description: 'Sữa tươi tiệt trùng Vinamilk 100% có đường, thơm ngon giàu canxi & vitamin.',
      originalPrice: 420000,
      wholesalePrice: 340000,
      savePercent: 19,
      imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'prod_lays_2',
      name: 'Combo Snack Khoai Tây Lay\'s Party',
      category: 'Snack & Bánh kẹo',
      packageSize: '20 bịch lớn (tự chọn vị)',
      description: 'Snack khoai tây Lays giòn rụm với các vị khoai tây tự nhiên, sườn nướng BBQ, tảo biển.',
      originalPrice: 240000,
      wholesalePrice: 185000,
      savePercent: 23,
      imageUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'prod_haohao_3',
      name: 'Gói Mỳ Tôm Hảo Hảo Tôm Chua Cay',
      category: 'Mỳ ăn liền',
      packageSize: '1 thùng sỉ (30 gói)',
      description: 'Mỳ ăn liền quốc dân Hảo Hảo hương vị Tôm Chua Cay chua thanh, cay nồng đậm đà.',
      originalPrice: 135000,
      wholesalePrice: 105000,
      savePercent: 22,
      imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'prod_coca_4',
      name: 'Gói Nước Ngọt Coca-Cola Tiết Kiệm',
      category: 'Nước giải khát',
      packageSize: '1 thùng sỉ (24 lon x 320ml)',
      description: 'Nước giải khát có ga Coca-Cola chính hãng mang lại cảm giác sảng khoái tức thì.',
      originalPrice: 265000,
      wholesalePrice: 210000,
      savePercent: 21,
      imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&auto=format&fit=crop&q=60',
    ),
    UniPackProduct(
      id: 'prod_aquafina_5',
      name: 'Gói Nước Khoáng Aquafina Tinh Khiết',
      category: 'Nước uống đóng chai',
      packageSize: '1 thùng sỉ (24 chai x 500ml)',
      description: 'Nước uống đóng chai Aquafina tinh khiết được lọc qua hệ thống tuần hoàn khép kín.',
      originalPrice: 120000,
      wholesalePrice: 88000,
      savePercent: 27,
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

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final updated = orders.map((o) {
      if (o.id == orderId) {
        return UniPackOrder(
          id: o.id,
          productName: o.productName,
          roomNumber: o.roomNumber,
          quantity: o.quantity,
          totalPrice: o.totalPrice,
          status: newStatus,
          createdAt: o.createdAt,
        );
      }
      return o;
    }).toList();
    final raw = jsonEncode(updated.map((o) => o.toJson()).toList());
    await prefs.setString(ApiConstants.unipackOrdersKey, raw);
  }
}
