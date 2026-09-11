import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String formatCurrency(dynamic amount) {
    if (amount == null) return '0 đ';
    final num numAmount = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    return _currencyFormat.format(numAmount).trim();
  }

  static String formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final DateTime dt = dateStr is DateTime ? dateStr : DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }

  static String formatDateTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final DateTime dt = dateStr is DateTime ? dateStr : DateTime.parse(dateStr.toString());
      return DateFormat('HH:mm dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }

  static String formatTimeAgo(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final DateTime dt = dateStr is DateTime ? dateStr : DateTime.parse(dateStr.toString());
      final Duration diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }
}
