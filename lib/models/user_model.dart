class KycDocumentsModel {
  final String? idCardFront;
  final String idCardFrontStatus; // 'EMPTY', 'PENDING', 'APPROVED', 'REJECTED'
  final String? idCardBack;
  final String idCardBackStatus;
  final String? propertyDoc;
  final String propertyDocStatus;
  final String? businessLicense;
  final String businessLicenseStatus;
  final String? idNumber;
  final String? submittedAt;
  final String? approvedAt;

  KycDocumentsModel({
    this.idCardFront,
    this.idCardFrontStatus = 'EMPTY',
    this.idCardBack,
    this.idCardBackStatus = 'EMPTY',
    this.propertyDoc,
    this.propertyDocStatus = 'EMPTY',
    this.businessLicense,
    this.businessLicenseStatus = 'EMPTY',
    this.idNumber = '079201008899',
    this.submittedAt,
    this.approvedAt,
  });

  bool get areAll4Approved =>
      idCardFront != null && idCardFrontStatus == 'APPROVED' &&
      idCardBack != null && idCardBackStatus == 'APPROVED' &&
      propertyDoc != null && propertyDocStatus == 'APPROVED' &&
      businessLicense != null && businessLicenseStatus == 'APPROVED';

  int get approvedCount => [
        idCardFront != null && idCardFrontStatus == 'APPROVED',
        idCardBack != null && idCardBackStatus == 'APPROVED',
        propertyDoc != null && propertyDocStatus == 'APPROVED',
        businessLicense != null && businessLicenseStatus == 'APPROVED',
      ].where((v) => v).length;

  int get uploadedCount => [
        idCardFront,
        idCardBack,
        propertyDoc,
        businessLicense,
      ].where((v) => v != null && v.isNotEmpty).length;

  factory KycDocumentsModel.fromJson(Map<String, dynamic> json) {
    return KycDocumentsModel(
      idCardFront: json['id_card_front'],
      idCardFrontStatus: json['id_card_front_status'] ?? (json['id_card_front'] != null ? 'PENDING' : 'EMPTY'),
      idCardBack: json['id_card_back'],
      idCardBackStatus: json['id_card_back_status'] ?? (json['id_card_back'] != null ? 'PENDING' : 'EMPTY'),
      propertyDoc: json['property_doc'],
      propertyDocStatus: json['property_doc_status'] ?? (json['property_doc'] != null ? 'PENDING' : 'EMPTY'),
      businessLicense: json['business_license'],
      businessLicenseStatus: json['business_license_status'] ?? (json['business_license'] != null ? 'PENDING' : 'EMPTY'),
      idNumber: json['id_number'] ?? '079201008899',
      submittedAt: json['submitted_at'],
      approvedAt: json['approved_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_card_front': idCardFront,
      'id_card_front_status': idCardFrontStatus,
      'id_card_back': idCardBack,
      'id_card_back_status': idCardBackStatus,
      'property_doc': propertyDoc,
      'property_doc_status': propertyDocStatus,
      'business_license': businessLicense,
      'business_license_status': businessLicenseStatus,
      'id_number': idNumber,
      'submitted_at': submittedAt,
      'approved_at': approvedAt,
    };
  }

  KycDocumentsModel copyWith({
    String? idCardFront,
    String? idCardFrontStatus,
    String? idCardBack,
    String? idCardBackStatus,
    String? propertyDoc,
    String? propertyDocStatus,
    String? businessLicense,
    String? businessLicenseStatus,
    String? idNumber,
    String? submittedAt,
    String? approvedAt,
  }) {
    return KycDocumentsModel(
      idCardFront: idCardFront ?? this.idCardFront,
      idCardFrontStatus: idCardFrontStatus ?? this.idCardFrontStatus,
      idCardBack: idCardBack ?? this.idCardBack,
      idCardBackStatus: idCardBackStatus ?? this.idCardBackStatus,
      propertyDoc: propertyDoc ?? this.propertyDoc,
      propertyDocStatus: propertyDocStatus ?? this.propertyDocStatus,
      businessLicense: businessLicense ?? this.businessLicense,
      businessLicenseStatus: businessLicenseStatus ?? this.businessLicenseStatus,
      idNumber: idNumber ?? this.idNumber,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}

class UserModel {
  final String id;
  final String? phone;
  final String fullName;
  final String role; // OWNER, TENANT, TECHNICIAN
  final String? email;
  final String? avatarUrl;
  final String verificationStatus; // 'UNVERIFIED', 'PENDING', 'VERIFIED', 'REJECTED'
  final bool isVerified;
  final KycDocumentsModel? kycDocuments;

  UserModel({
    required this.id,
    this.phone,
    required this.fullName,
    required this.role,
    this.email,
    this.avatarUrl,
    this.verificationStatus = 'PENDING',
    this.isVerified = false,
    this.kycDocuments,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final docsJson = json['kyc_documents'];
    final docs = docsJson != null && docsJson is Map<String, dynamic>
        ? KycDocumentsModel.fromJson(docsJson)
        : null;

    final role = json['role'] ?? 'OWNER';
    final isOwner = role == 'OWNER' || role == 'SUPERADMIN';
    final allApproved = docs != null && docs.areAll4Approved;
    final status = json['verification_status'] ?? (allApproved ? 'VERIFIED' : (isOwner ? 'PENDING' : 'VERIFIED'));
    final verified = json['is_verified'] == true || status == 'VERIFIED' || allApproved;

    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      phone: json['phone'],
      fullName: json['full_name'] ?? json['name'] ?? 'Người dùng',
      role: role,
      email: json['email'],
      avatarUrl: json['avatar_url'],
      verificationStatus: status,
      isVerified: verified,
      kycDocuments: docs,
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
      'verification_status': verificationStatus,
      'is_verified': isVerified,
      'kyc_documents': kycDocuments?.toJson(),
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? role,
    String? email,
    String? avatarUrl,
    String? verificationStatus,
    bool? isVerified,
    KycDocumentsModel? kycDocuments,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isVerified: isVerified ?? this.isVerified,
      kycDocuments: kycDocuments ?? this.kycDocuments,
    );
  }

  bool get isOwner => role == 'OWNER' || role == 'SUPERADMIN';
  bool get isTenant => role == 'TENANT';
  bool get isTechnician => role == 'TECHNICIAN';
}
