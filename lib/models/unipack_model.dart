class UniPackProduct {
  final String id;
  final String name;
  final String category;
  final String packageSize;
  final String description;
  final double originalPrice;
  final double wholesalePrice;
  final int savePercent;
  final String imageUrl;
  final String badge;

  UniPackProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.packageSize,
    required this.description,
    required this.originalPrice,
    required this.wholesalePrice,
    required this.savePercent,
    required this.imageUrl,
    this.badge = 'GIÁ SỈ',
  });
}

class UniPackCartItem {
  final UniPackProduct product;
  int quantity;

  UniPackCartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.wholesalePrice * quantity;
}

class UniPackOrder {
  final String id;
  final String productName;
  final String roomNumber;
  final int quantity;
  final double totalPrice;
  final String status; // PENDING, CONFIRMED, DELIVERED, CANCELLED
  final String createdAt;

  UniPackOrder({
    required this.id,
    required this.productName,
    required this.roomNumber,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory UniPackOrder.fromJson(Map<String, dynamic> json) {
    return UniPackOrder(
      id: json['id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      roomNumber: json['roomNumber'] ?? json['room_number'] ?? '',
      quantity: json['quantity'] ?? 1,
      totalPrice: (json['totalPrice'] ?? json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'roomNumber': roomNumber,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
