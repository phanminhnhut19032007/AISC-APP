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
  bool checked;

  UniPackCartItem({
    required this.product,
    this.quantity = 1,
    this.checked = true,
  });

  double get totalPrice => product.wholesalePrice * quantity;
}

class UniPackOrder {
  final String id;
  final String productName;
  final String roomNumber;
  final String receiverName;
  final String receiverPhone;
  final int quantity;
  final double totalPrice;
  final String paymentMethod; // 'COD' | 'VIETQR'
  final String status; // 'PENDING_SUNDAY_DELIVERY' | 'DELIVERED' | 'CANCELLED'
  final bool isPaid;
  final int createdAt; // timestamp in ms
  final int cancelDeadline; // timestamp in ms (1 hour cancel window)
  final String orderDate;

  UniPackOrder({
    required this.id,
    required this.productName,
    required this.roomNumber,
    this.receiverName = '',
    this.receiverPhone = '',
    required this.quantity,
    required this.totalPrice,
    this.paymentMethod = 'COD',
    required this.status,
    this.isPaid = false,
    required this.createdAt,
    required this.cancelDeadline,
    this.orderDate = '',
  });

  bool get isCanCancel {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (cancelDeadline - now) > 0 && status != 'CANCELLED' && status != 'DELIVERED';
  }

  int get remainingMs {
    final now = DateTime.now().millisecondsSinceEpoch;
    return cancelDeadline - now;
  }

  String get formattedRemainingTime {
    final diff = remainingMs;
    if (diff <= 0) return '00:00';
    final totalSeconds = (diff / 1000).floor();
    final mins = (totalSeconds / 60).floor();
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get formattedExactDeadline {
    final d = DateTime.fromMillisecondsSinceEpoch(cancelDeadline);
    final hours = d.hour.toString().padLeft(2, '0');
    final minutes = d.minute.toString().padLeft(2, '0');
    final seconds = d.second.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$hours:$minutes:$seconds $day/$month/$year';
  }

  UniPackOrder copyWith({
    String? id,
    String? productName,
    String? roomNumber,
    String? receiverName,
    String? receiverPhone,
    int? quantity,
    double? totalPrice,
    String? paymentMethod,
    String? status,
    bool? isPaid,
    int? createdAt,
    int? cancelDeadline,
    String? orderDate,
  }) {
    return UniPackOrder(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      roomNumber: roomNumber ?? this.roomNumber,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      cancelDeadline: cancelDeadline ?? this.cancelDeadline,
      orderDate: orderDate ?? this.orderDate,
    );
  }

  factory UniPackOrder.fromJson(Map<String, dynamic> json) {
    int parsedCreatedAt;
    if (json['createdAt'] is int) {
      parsedCreatedAt = json['createdAt'];
    } else if (json['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'])?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    } else {
      parsedCreatedAt = DateTime.now().millisecondsSinceEpoch;
    }

    int parsedDeadline;
    if (json['cancelDeadline'] is int) {
      parsedDeadline = json['cancelDeadline'];
    } else {
      parsedDeadline = parsedCreatedAt + 60 * 60 * 1000;
    }

    final rawStatus = json['status'] ?? 'PENDING_SUNDAY_DELIVERY';
    final normalizedStatus = rawStatus == 'PENDING' ? 'PENDING_SUNDAY_DELIVERY' : rawStatus;

    return UniPackOrder(
      id: json['id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      roomNumber: json['roomNumber'] ?? json['room_number'] ?? '',
      receiverName: json['receiverName'] ?? json['receiver_name'] ?? '',
      receiverPhone: json['receiverPhone'] ?? json['receiver_phone'] ?? '',
      quantity: json['quantity'] ?? 1,
      totalPrice: (json['totalPrice'] ?? json['total_price'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? json['payment_method'] ?? 'COD',
      status: normalizedStatus,
      isPaid: json['isPaid'] ?? json['is_paid'] ?? false,
      createdAt: parsedCreatedAt,
      cancelDeadline: parsedDeadline,
      orderDate: json['orderDate'] ?? json['order_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'roomNumber': roomNumber,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': status,
      'isPaid': isPaid,
      'createdAt': createdAt,
      'cancelDeadline': cancelDeadline,
      'orderDate': orderDate,
    };
  }
}
