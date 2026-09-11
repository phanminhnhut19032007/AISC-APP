class UserModel {
  final String id;
  final String? phone;
  final String fullName;
  final String role; // OWNER, TENANT, TECHNICIAN, SUPERADMIN
  final String? email;
  final String? avatarUrl;

  UserModel({
    required this.id,
    this.phone,
    required this.fullName,
    required this.role,
    this.email,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      phone: json['phone'],
      fullName: json['full_name'] ?? json['name'] ?? 'Người dùng',
      role: json['role'] ?? 'OWNER',
      email: json['email'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'full_name': fullName,
      'role': role,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }

  bool get isOwner => role == 'OWNER' || role == 'SUPERADMIN';
  bool get isTenant => role == 'TENANT';
  bool get isTechnician => role == 'TECHNICIAN';
}
