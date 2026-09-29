# 📱 AISC-APP — Ứng dụng Di động Quản lý Trọ & Căn hộ Thông minh (Flutter)

<div align="center">
  <p><strong>Phiên bản Mobile dành cho Chủ trọ & Cư dân thuê trọ — Đồng bộ 100% với hệ sinh thái REASY</strong></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge)](https://flutter.dev)
  [![Backend API](https://img.shields.io/badge/Backend-FastAPI%20Live-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://aisc-1.onrender.com/docs)
</div>

---

## 🛠️ Danh sách Công cụ & Tech Stack (Công nghệ sử dụng)

### 📱 1. Mobile App Architecture (Flutter / Dart)
| Thư viện / Công nghệ | Phiên bản | Vai trò & Mục đích sử dụng |
| :--- | :--- | :--- |
| **Flutter SDK** | `>= 3.13.2` | Bộ framework phát triển ứng dụng di động đa nền tảng (Android & iOS) hiệu năng Native 60-120fps. |
| **Dart** | `>= 3.0` | Ngôn ngữ lập trình hướng đối tượng định kiểu tĩnh, hỗ trợ Null-safety và biên dịch AOT tối ưu. |
| **Provider** | `^6.1.2` | Kiến trúc quản lý trạng thái (State Management) phản ứng nhanh, phân tách `AuthProvider` và `AppDataProvider`. |
| **Dio** | `^5.4.1` | HTTP Client xử lý kết nối RESTful API, tự động gắn JWT Token Bearer qua Interceptors, tự retry và xử lý lỗi mạng. |
| **SharedPreferences** | `^2.2.2` | Bộ nhớ đệm cục bộ (Local Storage) lưu phiên đăng nhập, JWT Token, mã phòng, lịch sử đọc thông báo và giỏ hàng UniPack. |
| **CachedNetworkImage** | `^3.3.1` | Tối ưu tải ảnh mạng, cache ảnh thẻ căn cước CCCD, ảnh phòng trọ và avatar để tiết kiệm dữ liệu di động. |
| **Intl** | `^0.19.0` | Định dạng tiền tệ VND (`NumberFormat.currency`), chuẩn hóa ngày giờ và ngôn ngữ tiếng Việt. |
| **Cupertino Icons & Material 3** | `^1.0.8` | Bộ icon thiết kế chuẩn mực iOS/Android, hỗ trợ theme hiện đại, bo góc mềm mại. |
| **HapticFeedback & Custom Siren** | Native API | Hiệu ứng rung phản hồi xúc giác khi bấm nút khẩn cấp SOS và icon còi báo động vector. |

---

### 🌐 2. Hệ sinh thái Kết nối & Backend Cloud
| Thành phần | Nền tảng / Công cụ | Vai trò |
| :--- | :--- | :--- |
| **Server Backend** | FastAPI (Python 3.11) | Máy chủ API RESTful và WebSocket phục vụ toàn bộ Web & Mobile. |
| **Live API Endpoint** | `https://aisc-1.onrender.com/api/v1` | Cổng API chung đồng bộ dữ liệu thời gian thực giữa Web và App. |
| **Giao thức SOS Khẩn cấp** | High-Frequency Polling (3.5s) | Cơ chế đồng bộ còi báo động khẩn cấp 2 chiều giữa điện thoại người thuê và máy tính chủ trọ. |
| **Thanh toán VietQR** | NAPAS 24/7 Engine | Quét mã VietQR động để thanh toán tiền phòng/điện nước tức thì. |
| **Đăng ký Số điện thoại** | SMS OTP Sim 6 số | Xác thực tài khoản với bộ đếm ngược 60 giây và mã OTP an toàn. |

---

## 🔑 Tài khoản Đăng nhập Hệ thống

Ứng dụng hỗ trợ chuyển đổi vai trò nhanh trên màn hình đăng nhập với 2 tài khoản:

| Vai trò | Số điện thoại | Mật khẩu | Tên hiển thị | Tính năng chính |
| :--- | :--- | :--- | :--- | :--- |
| 🏢 **Chủ trọ** | `0388430402` | `MinhNhut1` | **Chu tro** | Quản lý tòa nhà (`MC892`), danh sách phòng (`P101A`), chốt số điện nước, nộp hồ sơ KYC 4 giấy tờ lấy Tích Xanh, tiếp nhận tin báo khẩn cấp SOS. |
| 👥 **Người thuê** | `0388430402` | `MinhNhut2` | **Minh Nhut** | Xem hóa đơn, quét VietQR, gửi yêu cầu sửa chữa phòng, phát báo động khẩn cấp SOS khi gặp sự cố, dịch vụ UniPack. |

> [!NOTE]
> Cổng duyệt KYC của **Quản trị viên (Admin)** chỉ hoạt động trên nền tảng Website để đảm bảo tính an toàn và bảo mật hệ thống.

---

## ⚡ Hướng dẫn Chạy ứng dụng (Dành cho Developer)

### 1. Cài đặt Flutter & Kiểm tra môi trường:
```bash
flutter doctor
```

### 2. Cài đặt các thư viện dependencies:
```bash
flutter pub get
```

### 3. Chạy trực tiếp trên Thiết bị thật / Máy ảo:
```bash
flutter run
```

### 4. Đóng gói file cài đặt Android (APK):
```bash
# Đóng gói file APK Release hoàn chỉnh
flutter build apk --release
```
*File APK xuất ra tại:* `build/app/outputs/flutter-apk/app-release.apk`
