import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<UserModel> login(
    String phone,
    String password, {
    String? role,
    String? buildingCode,
    String? roomCode,
  }) async {
    try {
      final body = <String, dynamic>{'phone': phone, 'password': password};
      if (role != null) body['role'] = role;
      if (buildingCode != null) body['building_code'] = buildingCode;
      if (roomCode != null) body['room_code'] = roomCode;

      final response = await _api.post(
        ApiConstants.login,
        data: body,
      );

      final data = response.data;
      final token = data['access_token'];
      final user = UserModel.fromJson(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.tokenKey, token);
      await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
      await prefs.setString('user_password_${user.phone}', password);
      if (buildingCode != null) {
        await prefs.setString(ApiConstants.demoTenantBuildingKey, buildingCode);
      }
      if (roomCode != null) {
        await prefs.setString(ApiConstants.demoTenantRoomKey, roomCode);
      }

      return user;
    } catch (e) {
      // Fallback trực tiếp cho 2 tài khoản Chu tro & Minh Nhut
      if (phone == '0388430402') {
        final prefs = await SharedPreferences.getInstance();
        if ((role == 'OWNER' || role == null) && password == 'MinhNhut1') {
          // Check if previous KYC state was saved
          final savedKycStr = prefs.getString('saved_kyc_0388430402');
          KycDocumentsModel? savedKyc;
          if (savedKycStr != null) {
            try {
              savedKyc = KycDocumentsModel.fromJson(jsonDecode(savedKycStr));
            } catch (_) {}
          }

          final user = UserModel(
            id: '6b123c40-0572-4985-aa08-5d7b9abd4f76',
            fullName: 'Chu tro',
            phone: '0388430402',
            role: 'OWNER',
            verificationStatus: savedKyc?.areAll4Approved == true ? 'VERIFIED' : 'PENDING',
            isVerified: savedKyc?.areAll4Approved == true,
            kycDocuments: savedKyc,
          );
          await prefs.setString(ApiConstants.tokenKey, 'mock_token_owner_0388430402');
          await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
          await prefs.setString('user_password_0388430402', password);
          return user;
        } else if ((role == 'TENANT' || role == null) && password == 'MinhNhut2') {
          final user = UserModel(
            id: '3fba1d98-ec4a-4eb5-dc74-26586abc75',
            fullName: 'Minh Nhut',
            phone: '0388430402',
            role: 'TENANT',
            verificationStatus: 'VERIFIED',
            isVerified: true,
          );
          await prefs.setString(ApiConstants.tokenKey, 'mock_token_tenant_0388430402');
          await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
          await prefs.setString('user_password_0388430402', password);
          if (buildingCode != null) {
            await prefs.setString(ApiConstants.demoTenantBuildingKey, buildingCode);
          }
          if (roomCode != null) {
            await prefs.setString(ApiConstants.demoTenantRoomKey, roomCode);
          }
          return user;
        }
      }
      rethrow;
    }
  }

  /// Gửi yêu cầu OTP đến SĐT
  Future<String> requestOtp(String phone) async {
    try {
      final res = await _api.post(
        ApiConstants.sendOtp,
        data: {'phone': phone},
      );
      if (res.data != null && res.data['otp_demo'] != null) {
        return res.data['otp_demo'].toString();
      }
    } catch (_) {}

    // Fallback: sinh mã OTP 6 số đẹp
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_otp_$phone', randomOtp);
    return randomOtp;
  }

  /// Xác thực OTP và đăng ký tài khoản mới
  Future<UserModel> verifyOtpAndRegister({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    required String otpCode,
    KycDocumentsModel? kycDocs,
  }) async {
    try {
      final res = await _api.post(
        ApiConstants.register,
        data: {
          'full_name': fullName,
          'phone': phone,
          'password': password,
          'role': role,
          'otp_code': otpCode,
        },
      );
      final data = res.data;
      final token = data['access_token'];
      final user = UserModel.fromJson(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.tokenKey, token);
      await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
      await prefs.setString('user_password_$phone', password);
      return user;
    } catch (_) {
      // Fallback offline / instant register
      final isOwner = role == 'OWNER';
      final allApproved = kycDocs?.areAll4Approved ?? false;
      final user = UserModel(
        id: 'user_reg_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        phone: phone,
        role: role,
        verificationStatus: allApproved ? 'VERIFIED' : (isOwner ? 'PENDING' : 'VERIFIED'),
        isVerified: allApproved || !isOwner,
        kycDocuments: kycDocs,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.tokenKey, 'token_${user.id}');
      await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
      await prefs.setString('user_password_$phone', password);
      if (kycDocs != null) {
        await prefs.setString('saved_kyc_$phone', jsonEncode(kycDocs.toJson()));
      }
      return user;
    }
  }

  /// Đăng nhập mạng xã hội (Google / Facebook)
  Future<UserModel> loginWithSocial(String provider, String role) async {
    final isOwner = role == 'OWNER';
    final user = UserModel(
      id: '${provider.toLowerCase()}_user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: provider == 'Google' ? (isOwner ? 'Chu Tro Google' : 'Minh Nhut Google') : (isOwner ? 'Chu Tro FB' : 'Minh Nhut FB'),
      phone: '0388430402',
      email: '${provider.toLowerCase()}_user@reasy.vn',
      role: role,
      verificationStatus: isOwner ? 'PENDING' : 'VERIFIED',
      isVerified: !isOwner,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, 'token_${provider.toLowerCase()}');
    await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
    return user;
  }

  /// Cập nhật hồ sơ KYC cho Chủ trọ
  Future<UserModel> updateKycStatus(KycDocumentsModel kycDocs, {String? status}) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(ApiConstants.userKey);
    UserModel currentUser;
    if (userJson != null) {
      currentUser = UserModel.fromJson(jsonDecode(userJson));
    } else {
      currentUser = UserModel(
        id: '6b123c40-0572-4985-aa08-5d7b9abd4f76',
        fullName: 'Chu tro',
        phone: '0388430402',
        role: 'OWNER',
      );
    }

    final allApproved = kycDocs.areAll4Approved;
    final finalStatus = status ?? (allApproved ? 'VERIFIED' : 'PENDING');

    final updated = currentUser.copyWith(
      kycDocuments: kycDocs,
      verificationStatus: finalStatus,
      isVerified: finalStatus == 'VERIFIED',
    );

    await prefs.setString(ApiConstants.userKey, jsonEncode(updated.toJson()));
    if (updated.phone != null) {
      await prefs.setString('saved_kyc_${updated.phone}', jsonEncode(kycDocs.toJson()));
    }
    return updated;
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
