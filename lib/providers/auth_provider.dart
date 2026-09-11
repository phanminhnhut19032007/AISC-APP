import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _tenantRoomCode = '101';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get tenantRoomCode => _tenantRoomCode;

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

  Future<bool> login(String phone, String password, {String? roomCode}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.login(phone, password);
      if (roomCode != null && roomCode.isNotEmpty) {
        _tenantRoomCode = roomCode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.demoTenantRoomKey, roomCode);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
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
    final defaultDemoPass = _currentUser!.isTenant ? 'tenant123' : 'smartrent123';
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
    notifyListeners();
  }
}
