import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

void showKycVerificationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const KycVerificationDialog(),
  );
}

class KycVerificationDialog extends StatefulWidget {
  const KycVerificationDialog({super.key});

  @override
  State<KycVerificationDialog> createState() => _KycVerificationDialogState();
}

class _KycVerificationDialogState extends State<KycVerificationDialog> {
  late KycDocumentsModel _docs;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _docs = user?.kycDocuments ?? KycDocumentsModel();
  }

  void _simulateUploadSlot(String slotKey) {
    setState(() {
      switch (slotKey) {
        case 'id_front':
          _docs = _docs.copyWith(
            idCardFront: 'mock_front_image.jpg',
            idCardFrontStatus: 'PENDING',
          );
          break;
        case 'id_back':
          _docs = _docs.copyWith(
            idCardBack: 'mock_back_image.jpg',
            idCardBackStatus: 'PENDING',
          );
          break;
        case 'property':
          _docs = _docs.copyWith(
            propertyDoc: 'mock_property_doc.jpg',
            propertyDocStatus: 'PENDING',
          );
          break;
        case 'business':
          _docs = _docs.copyWith(
            businessLicense: 'mock_business_license.jpg',
            businessLicenseStatus: 'PENDING',
          );
          break;
      }
    });
  }

  void _simulateApproveAll() {
    setState(() {
      _docs = KycDocumentsModel(
        idCardFront: 'cccd_front_approved.jpg',
        idCardFrontStatus: 'APPROVED',
        idCardBack: 'cccd_back_approved.jpg',
        idCardBackStatus: 'APPROVED',
        propertyDoc: 'so_hong_approved.jpg',
        propertyDocStatus: 'APPROVED',
        businessLicense: 'pccc_approved.jpg',
        businessLicenseStatus: 'APPROVED',
        idNumber: '079201008899',
        submittedAt: DateTime.now().toIso8601String(),
        approvedAt: DateTime.now().toIso8601String(),
      );
    });
  }

  void _clearSlot(String slotKey) {
    setState(() {
      switch (slotKey) {
        case 'id_front':
          _docs = _docs.copyWith(idCardFront: '', idCardFrontStatus: 'EMPTY');
          break;
        case 'id_back':
          _docs = _docs.copyWith(idCardBack: '', idCardBackStatus: 'EMPTY');
          break;
        case 'property':
          _docs = _docs.copyWith(propertyDoc: '', propertyDocStatus: 'EMPTY');
          break;
        case 'business':
          _docs = _docs.copyWith(businessLicense: '', businessLicenseStatus: 'EMPTY');
          break;
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    final allApproved = _docs.areAll4Approved;
    final newStatus = allApproved ? 'VERIFIED' : (_docs.uploadedCount > 0 ? 'PENDING' : 'UNVERIFIED');

    await auth.updateKyc(_docs, status: newStatus);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: allApproved ? const Color(0xFF059669) : const Color(0xFF2563EB),
          content: Text(
            allApproved
                ? 'Chúc mừng! Hồ sơ KYC đã được duyệt - Huy hiệu Tích Xanh kích hoạt!'
                : 'Đã nộp hồ sơ xác minh KYC thành công. Đang chờ duyệt.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allApproved = _docs.areAll4Approved;
    final uploadedCount = _docs.uploadedCount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: allApproved ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      allApproved ? Icons.verified_rounded : Icons.shield_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xác minh Danh tính Chủ trọ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          allApproved
                              ? 'Đã xác minh chính chủ (Tích Xanh)'
                              : 'Hồ sơ 4 mục pháp lý theo quy định',
                          style: TextStyle(
                            color: allApproved ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Progress Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: allApproved
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: allApproved
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allApproved
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: allApproved
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allApproved
                                    ? 'Đã duyệt toàn bộ 4/4 chứng từ'
                                    : 'Đã hoàn tất $uploadedCount/4 mục hồ sơ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: allApproved
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                allApproved
                                    ? 'Hồ sơ đã được lưu trữ vĩnh viễn trên hệ thống'
                                    : 'Vui lòng cung cấp đủ 4 loại giấy tờ để nhận tích xanh',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: allApproved
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4 Slots
                  _buildDocSlot(
                    number: '1',
                    title: 'CCCD Mặt trước',
                    subtitle: 'Khớp tên Chủ trọ Chu tro',
                    slotKey: 'id_front',
                    image: _docs.idCardFront,
                    status: _docs.idCardFrontStatus,
                  ),
                  const SizedBox(height: 10),

                  _buildDocSlot(
                    number: '2',
                    title: 'CCCD Mặt sau',
                    subtitle: 'Có vân tay & chip bảo mật',
                    slotKey: 'id_back',
                    image: _docs.idCardBack,
                    status: _docs.idCardBackStatus,
                  ),
                  const SizedBox(height: 10),

                  _buildDocSlot(
                    number: '3',
                    title: 'Sổ hồng / HĐ Thuê',
                    subtitle: 'Chứng minh quyền quản lý nhà trọ',
                    slotKey: 'property',
                    image: _docs.propertyDoc,
                    status: _docs.propertyDocStatus,
                  ),
                  const SizedBox(height: 10),

                  _buildDocSlot(
                    number: '4',
                    title: 'Giấy phép KD / PCCC',
                    subtitle: 'Đạt chuẩn an ninh phòng cháy chữa cháy',
                    slotKey: 'business',
                    image: _docs.businessLicense,
                    status: _docs.businessLicenseStatus,
                  ),

                  const SizedBox(height: 14),

                  // OCR Inspection Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            const Text(
                              'Xác thực OCR CCCD tự động',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AI OCR 100%',
                                style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số định danh cá nhân:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              _docs.idNumber ?? '079201008899',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Họ và tên tra cứu:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text('CHU TRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Demo Helper: Approve all test button
                  OutlinedButton.icon(
                    onPressed: _simulateApproveAll,
                    icon: const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF059669)),
                    label: const Text(
                      'Mô phỏng Phê duyệt 4/4 chứng từ (Nhận Tích Xanh)',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      backgroundColor: const Color(0xFFF0FDF4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Footer Submit
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allApproved ? const Color(0xFF059669) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              allApproved ? 'Lưu & Kích hoạt Tích Xanh' : 'Lưu hồ sơ KYC',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocSlot({
    required String number,
    required String title,
    required String subtitle,
    required String slotKey,
    required String? image,
    required String status,
  }) {
    final hasImage = image != null && image.isNotEmpty;
    final isApproved = status == 'APPROVED';
    final isPending = hasImage && !isApproved;

    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor = const Color(0xFFF8FAFC);

    if (isApproved) {
      borderColor = const Color(0xFFA7F3D0);
      bgColor = const Color(0xFFF0FDF4);
    } else if (isPending) {
      borderColor = const Color(0xFFFDE68A);
      bgColor = const Color(0xFFFFFBEB);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isApproved ? const Color(0xFF059669) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              // Status Badge
              if (isApproved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text('Đã duyệt', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      SizedBox(width: 3),
                      Text('Chờ duyệt', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Chưa có ảnh', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold)),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Upload / Action bar
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _simulateUploadSlot(slotKey),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(hasImage ? Icons.cached_rounded : Icons.camera_alt_outlined, size: 14, color: const Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          hasImage ? 'Đổi ảnh giấy tờ' : 'Tải lên giấy tờ',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _clearSlot(slotKey),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
