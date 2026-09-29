import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoginSuccess = false;
  String? _successUserName;
  String? _tenantRoomCode = 'P101A';
  String? _tenantBuildingCode = 'MC892';
  bool _isLoadingAccount = false;
  String? _loadingUserName;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoginSuccess => _isLoginSuccess;
  String? get successUserName => _successUserName;
  bool get isAuthenticated => _currentUser != null;
  String? get tenantRoomCode => _tenantRoomCode;
  String? get tenantBuildingCode => _tenantBuildingCode;
  bool get isLoadingAccount => _isLoadingAccount;
  String? get loadingUserName => _loadingUserName;

  void finishAccountLoading() {
    _isLoadingAccount = false;
    notifyListeners();
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getSavedUser();
    final prefs = await SharedPreferences.getInstance();
    _tenantRoomCode = prefs.getString(ApiConstants.demoTenantRoomKey) ?? 'P101A';
    _tenantBuildingCode = prefs.getString(ApiConstants.demoTenantBuildingKey) ?? 'MC892';

    _isLoading = false;
    notifyListeners();

    // Refresh user in background
    if (_currentUser != null) {
      final updated = await _authService.fetchMe();
      if (updated != null) {
        _currentUser = updated;
        notifyListeners();
      }
    }
  }

  Future<bool> login(
    String phone,
    String password, {
    String? roomCode,
    String? buildingCode,
    String? role,
  }) async {
    _isLoading = true;
    _isLoginSuccess = false;
    notifyListeners();

    try {
      final user = await _authService.login(
        phone,
        password,
        role: role,
        buildingCode: buildingCode,
        roomCode: roomCode,
      );
      if (roomCode != null && roomCode.isNotEmpty) {
        _tenantRoomCode = roomCode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.demoTenantRoomKey, roomCode);
      }
      if (buildingCode != null && buildingCode.isNotEmpty) {
        _tenantBuildingCode = buildingCode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.demoTenantBuildingKey, buildingCode);
      }
      _isLoginSuccess = true;
      _successUserName = user.fullName;
      _isLoading = false;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 350));
      _currentUser = user;
      _isLoadingAccount = true;
      _loadingUserName = user.fullName;
      _isLoginSuccess = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _isLoginSuccess = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Yêu cầu gửi mã OTP
  Future<String> requestOtp(String phone) async {
    return await _authService.requestOtp(phone);
  }

  /// Xác thực OTP và đăng ký
  Future<bool> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    required String otpCode,
    KycDocumentsModel? kycDocs,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.verifyOtpAndRegister(
        fullName: fullName,
        phone: phone,
        password: password,
        role: role,
        otpCode: otpCode,
        kycDocs: kycDocs,
      );

      _isLoginSuccess = true;
      _successUserName = user.fullName;
      _isLoading = false;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 350));
      _currentUser = user;
      _isLoadingAccount = true;
      _loadingUserName = user.fullName;
      _isLoginSuccess = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Đăng nhập mạng xã hội
  Future<bool> loginWithOAuth(String provider, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.loginWithSocial(provider, role);
      _isLoginSuccess = true;
      _successUserName = user.fullName;
      _isLoading = false;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 350));
      _currentUser = user;
      _isLoadingAccount = true;
      _loadingUserName = user.fullName;
      _isLoginSuccess = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cập nhật KYC
  Future<void> updateKyc(KycDocumentsModel kycDocs, {String? status}) async {
    final updated = await _authService.updateKycStatus(kycDocs, status: status);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('Vui lòng đăng nhập lại để đổi mật khẩu');
    }

    if (newPassword.trim().isEmpty) {
      throw Exception('Mật khẩu mới không được để trống');
    }

    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự');
    }

    if (newPassword != confirmPassword) {
      throw Exception('Mật khẩu xác nhận không khớp');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.changePassword(oldPassword, newPassword);
      if (_currentUser?.phone != null) {
        await _authService.savePassword(_currentUser!.phone!, newPassword);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  String defaultDemoPass(String role) {
    return role == 'TENANT' ? 'MinhNhut2' : 'MinhNhut1';
  }
}
