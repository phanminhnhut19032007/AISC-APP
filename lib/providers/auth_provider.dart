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
  String? _tenantRoomCode = '101';
  bool _isLoadingAccount = false;
  String? _loadingUserName;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoginSuccess => _isLoginSuccess;
  String? get successUserName => _successUserName;
  bool get isAuthenticated => _currentUser != null;
  String? get tenantRoomCode => _tenantRoomCode;
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
    _tenantRoomCode = prefs.getString(ApiConstants.demoTenantRoomKey) ?? '101';

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

  Future<bool> login(String phone, String password, {String? roomCode, String? role}) async {
    _isLoading = true;
    _isLoginSuccess = false;
    notifyListeners();

    try {
      final user = await _authService.login(phone, password, role: role);
      if (roomCode != null && roomCode.isNotEmpty) {
        _tenantRoomCode = roomCode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.demoTenantRoomKey, roomCode);
      }
      _isLoginSuccess = true;
      _successUserName = user.fullName;
      _isLoading = false;
      notifyListeners();

      // Short celebration then trigger animated account loading screen with % progress
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
      throw Exception('Mật khẩu xác nhận không khớp với mật khẩu mới');
    }

    if (oldPassword == newPassword) {
      throw Exception('Mật khẩu mới không được trùng với mật khẩu cũ');
    }

    // Verify old password
    final phoneKey = _currentUser!.phone ?? _currentUser!.id;
    final savedPass = await _authService.getSavedPassword(phoneKey);
    final defaultDemoPass = _currentUser!.isTenant ? 'MinhNhut2' : 'MinhNhut1';
    final expectedPass = savedPass ?? defaultDemoPass;

    if (oldPassword != expectedPass) {
      throw Exception('Mật khẩu cũ không chính xác');
    }

    // Call live API to update backend password
    try {
      await _authService.changePassword(oldPassword, newPassword);
    } catch (_) {}

    // Save new password locally
    await _authService.savePassword(phoneKey, newPassword);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isLoadingAccount = false;
    notifyListeners();
  }
}
