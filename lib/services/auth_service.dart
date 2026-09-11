import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<UserModel> login(String phone, String password) async {
    final response = await _api.post(
      ApiConstants.login,
      data: {'phone': phone, 'password': password},
    );

    final data = response.data;
    final token = data['access_token'];
    final user = UserModel.fromJson(data);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
    await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
    await prefs.setString('user_password_${user.phone}', password);

    return user;
  }

  Future<String?> getSavedPassword(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_password_$phone');
  }

  Future<void> savePassword(String phone, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_password_$phone', newPassword);
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(ApiConstants.userKey);
    final token = prefs.getString(ApiConstants.tokenKey);
    if (token == null || userJson == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> fetchMe() async {
    try {
      final response = await _api.get(ApiConstants.me);
      final user = UserModel.fromJson(response.data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.post(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
    await prefs.remove(ApiConstants.userKey);
  }
}
