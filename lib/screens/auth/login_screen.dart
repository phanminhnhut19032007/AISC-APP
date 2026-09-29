import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animated_pressable.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  String _selectedRole = ''; // '' (role select), 'OWNER', 'TENANT'
  String _authMode = 'LOGIN'; // 'LOGIN', 'REGISTER'
  String _regStep = 'INPUT_FORM'; // 'INPUT_FORM', 'VERIFY_OTP', 'OWNER_KYC'

  // Login Form Controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _buildingCodeController = TextEditingController(text: 'MC892');
  final _roomCodeController = TextEditingController(text: 'P101A');
  bool _obscurePassword = true;

  // Register Form Controllers
  final _regFullNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;

  // 6-digit OTP Controllers & Focus Nodes
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  String? _demoOtp;
  int _countdown = 0;
  Timer? _countdownTimer;

  // KYC Upload States for Owner Registration
  KycDocumentsModel _regKycDocs = KycDocumentsModel();

  bool _isSubmitting = false;
  String? _errorMessage;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _buildingCodeController.dispose();
    _roomCodeController.dispose();
    _regFullNameController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      _authMode = 'LOGIN';
      _regStep = 'INPUT_FORM';
      _errorMessage = null;
      _phoneController.clear();
      _passwordController.clear();
      if (role == 'TENANT') {
        _buildingCodeController.text = 'MC892';
        _roomCodeController.text = 'P101A';
      }
    });
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final buildingCode = _buildingCodeController.text.trim();
    final roomCode = _roomCodeController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ số điện thoại và mật khẩu.');
      return;
    }

    if (_selectedRole == 'TENANT' && (buildingCode.isEmpty || roomCode.isEmpty)) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ Mã tòa và Mã phòng.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.login(
        phone,
        password,
        role: _selectedRole,
        buildingCode: buildingCode,
        roomCode: roomCode,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _handleRequestOtp() async {
    final fullName = _regFullNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final pass = _regPasswordController.text.trim();
    final confirmPass = _regConfirmPasswordController.text.trim();

    if (fullName.isEmpty || phone.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng điền đầy đủ tất cả các trường.');
      return;
    }

    if (pass.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }

    if (pass != confirmPass) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final otp = await auth.requestOtp(phone);
      setState(() {
        _demoOtp = otp;
        _regStep = 'VERIFY_OTP';
        _isSubmitting = false;
        for (final c in _otpControllers) {
          c.clear();
        }
      });
      _startCountdown();
      if (_otpFocusNodes[0].canRequestFocus) {
        _otpFocusNodes[0].requestFocus();
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Không thể gửi mã OTP. Vui lòng thử lại.';
        _isSubmitting = false;
      });
    }
  }

  void _fillOtp(String otp) {
    if (otp.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = otp[i];
      }
      setState(() {});
      _otpFocusNodes[5].requestFocus();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ 6 chữ số OTP.');
      return;
    }

    if (_selectedRole == 'OWNER' && _regStep == 'VERIFY_OTP') {
      // Owner proceeds to optional KYC step
      setState(() {
        _regStep = 'OWNER_KYC';
        _errorMessage = null;
      });
      return;
    }

    await _finalizeRegistration();
  }

  Future<void> _finalizeRegistration() async {
    final fullName = _regFullNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final pass = _regPasswordController.text.trim();
    final otp = _otpControllers.map((c) => c.text).join();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.register(
        fullName: fullName,
        phone: phone,
        password: pass,
        role: _selectedRole,
        otpCode: otp,
        kycDocs: _selectedRole == 'OWNER' ? _regKycDocs : null,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Dynamic Animated Aurora Waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AuroraWavesPainter(
                    animationValue: _animController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 2. Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Card
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                                  blurRadius: 28,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF818CF8).withValues(alpha: 0.14),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 68,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Text('REASY', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Brand Header
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          children: [
                            TextSpan(text: 'Chào mừng đến '),
                            TextSpan(
                              text: 'REASY',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Hệ thống quản lý phòng trọ & cư dân thông minh',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Card Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _selectedRole.isEmpty
                            ? _buildRoleSelectionView()
                            : _buildFormView(auth),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        '© 2026 REASY • Nền tảng quản lý phòng trọ thế hệ mới',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Role Selection View (Chủ trọ vs Cư dân người thuê)
  Widget _buildRoleSelectionView() {
    return Column(
      children: [
        const Text(
          'Xác nhận vai trò truy cập',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vui lòng chọn cổng đăng nhập của bạn để tiếp tục',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Option 1: Chủ trọ
        _buildRoleCard(
          role: 'OWNER',
          title: 'Chủ trọ / Quản trị',
          subtitle: 'Quản lý tòa nhà, hóa đơn, sự cố & nộp KYC',
          icon: Icons.apartment_rounded,
          iconBg: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF2563EB),
          borderColor: const Color(0xFFBFDBFE),
          onTap: () => _selectRole('OWNER'),
        ),
        const SizedBox(height: 12),

        // Option 2: Cư dân / Người thuê
        _buildRoleCard(
          role: 'TENANT',
          title: 'Cư dân / Người thuê phòng',
          subtitle: 'Xem hóa đơn, báo sự cố & tiện ích phòng',
          icon: Icons.people_alt_rounded,
          iconBg: const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFD97706),
          borderColor: const Color(0xFFFDE68A),
          onTap: () => _selectRole('TENANT'),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // 2. Form View (Login or Register)
  Widget _buildFormView(AuthProvider auth) {
    final isOwner = _selectedRole == 'OWNER';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Bar: Back Button & Role Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                if (_authMode == 'REGISTER' && _regStep != 'INPUT_FORM') {
                  setState(() {
                    if (_regStep == 'OWNER_KYC') {
                      _regStep = 'VERIFY_OTP';
                    } else {
                      _regStep = 'INPUT_FORM';
                    }
                    _errorMessage = null;
                  });
                } else {
                  setState(() {
                    _selectedRole = '';
                    _authMode = 'LOGIN';
                    _regStep = 'INPUT_FORM';
                    _errorMessage = null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF475569)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOwner ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOwner ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                isOwner ? '🏢 Chủ trọ / Quản trị' : '👥 Cư dân người thuê',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isOwner ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Segmented Tab Switcher (Đăng nhập vs Đăng ký bằng số điện thoại)
        if (_regStep == 'INPUT_FORM')
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _authMode = 'LOGIN';
                      _errorMessage = null;
                    }),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _authMode == 'LOGIN' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _authMode == 'LOGIN'
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _authMode == 'LOGIN' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _authMode = 'REGISTER';
                      _errorMessage = null;
                    }),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _authMode == 'REGISTER'
                            ? (isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _authMode == 'REGISTER'
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            size: 13,
                            color: _authMode == 'REGISTER' ? Colors.white : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đăng ký bằng SĐT',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _authMode == 'REGISTER' ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // TAB 1: LOGIN FORM
        if (_authMode == 'LOGIN') ...[
          _buildLoginForm(isOwner, auth),
        ] else ...[
          // TAB 2: REGISTER FORM
          if (_regStep == 'INPUT_FORM')
            _buildRegisterInputForm(isOwner)
          else if (_regStep == 'VERIFY_OTP')
            _buildRegisterOtpForm(isOwner)
          else
            _buildOwnerKycForm(),
        ],
      ],
    );
  }

  // ----------------------------------------------------
  // SUB-FORMS
  // ----------------------------------------------------

  Widget _buildLoginForm(bool isOwner, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone Input
        const Text('Số điện thoại đăng nhập', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '0388430402',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF64748B), size: 17),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFF59E0B), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
        const SizedBox(height: 10),

        // Building & Room Code for Tenant
        if (!isOwner) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mã tòa *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _buildingCodeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'MC892',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mã phòng *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _roomCodeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'P101A',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Password Input
        const Text('Mật khẩu', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 17),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF64748B),
                size: 19,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFF59E0B), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),

        // Quick-Fill Card matching Web
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isOwner ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isOwner ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwner ? '🏢 Tài khoản Chủ trọ' : '👥 Tài khoản Cư dân thuê phòng',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isOwner ? const Color(0xFF1E3A8A) : const Color(0xFF78350F),
                      ),
                    ),
                    Text(
                      isOwner
                          ? '0388430402 | MinhNhut1'
                          : '0388430402 | MinhNhut2 | MC892 - P101A',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _phoneController.text = '0388430402';
                    _passwordController.text = isOwner ? 'MinhNhut1' : 'MinhNhut2';
                    if (!isOwner) {
                      _buildingCodeController.text = 'MC892';
                      _roomCodeController.text = 'P101A';
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isOwner ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    'Điền nhanh',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOwner ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],

        // Submit Button
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 44),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Đăng nhập vào hệ thống', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 15),
                  ],
                ),
        ),

        // Social Logins
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('HOẶC TIẾP TỤC VỚI', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => auth.loginWithOAuth('Google', _selectedRole),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFEA4335))),
                    SizedBox(width: 6),
                    Text('Google', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => auth.loginWithOAuth('Facebook', _selectedRole),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('f', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1877F2))),
                    SizedBox(width: 6),
                    Text('Facebook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Register link
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _authMode = 'REGISTER';
              _regStep = 'INPUT_FORM';
              _errorMessage = null;
            }),
            child: Text(
              'Chưa có tài khoản? Đăng ký bằng số điện thoại',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // REGISTER: STEP 1 (INPUT FORM)
  // ----------------------------------------------------
  Widget _buildRegisterInputForm(bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Họ và tên *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _regFullNameController,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Nguyễn Văn A',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 17),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),

        const Text('Số điện thoại đăng ký *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _regPhoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '0912345678',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF64748B), size: 17),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),

        const Text('Mật khẩu (tối thiểu 6 ký tự) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _regPasswordController,
          obscureText: _obscureRegPassword,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 17),
            suffixIcon: IconButton(
              icon: Icon(_obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),

        const Text('Xác nhận mật khẩu *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _regConfirmPasswordController,
          obscureText: _obscureRegConfirmPassword,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 17),
            suffixIcon: IconButton(
              icon: Icon(_obscureRegConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: () => setState(() => _obscureRegConfirmPassword = !_obscureRegConfirmPassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 15),
                const SizedBox(width: 6),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleRequestOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 44),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smartphone_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Nhận mã OTP xác thực', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 15),
                  ],
                ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // REGISTER: STEP 2 (VERIFY 6-DIGIT OTP)
  // ----------------------------------------------------
  Widget _buildRegisterOtpForm(bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Icon(Icons.security_rounded, color: Color(0xFFD97706), size: 24),
        ),
        const SizedBox(height: 8),
        const Text(
          'Xác thực mã bảo mật OTP',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 2),
        Text(
          'Gửi qua SMS tới số ${_regPhoneController.text}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        // Simulated SMS Banner
        if (_demoOtp != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sms_rounded, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tin nhắn SMS (Mô phỏng)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      Text(
                        'Mã OTP: $_demoOtp',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB45309), fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _fillOtp(_demoOtp!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Điền nhanh', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // 6 PIN Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              height: 50,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706), width: 2)),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (val.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                  setState(() {});
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Resend countdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _regStep = 'INPUT_FORM'),
              child: const Text('← Đổi số điện thoại', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            _countdown > 0
                ? Text('Gửi lại sau ${_countdown}s', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
                : InkWell(
                    onTap: _handleRequestOtp,
                    child: Text(
                      'Gửi lại mã OTP',
                      style: TextStyle(fontSize: 11, color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706), fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
        ],

        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleVerifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 44),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  isOwner ? 'Tiếp tục: Xác minh Chủ trọ (KYC)' : 'Xác thực & Hoàn tất Đăng ký',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // REGISTER: STEP 3 (OWNER KYC STEP)
  // ----------------------------------------------------
  Widget _buildOwnerKycForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xác minh Danh tính Chủ trọ (KYC)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                Text('Nhận huy hiệu Tích Xanh Chính Chủ', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 slots brief
        _buildMiniSlot('1. CCCD Mặt trước', _regKycDocs.idCardFront != null, () {
          setState(() => _regKycDocs = _regKycDocs.copyWith(idCardFront: 'front.jpg', idCardFrontStatus: 'PENDING'));
        }),
        const SizedBox(height: 6),
        _buildMiniSlot('2. CCCD Mặt sau', _regKycDocs.idCardBack != null, () {
          setState(() => _regKycDocs = _regKycDocs.copyWith(idCardBack: 'back.jpg', idCardBackStatus: 'PENDING'));
        }),
        const SizedBox(height: 6),
        _buildMiniSlot('3. Sổ hồng / HĐ Thuê', _regKycDocs.propertyDoc != null, () {
          setState(() => _regKycDocs = _regKycDocs.copyWith(propertyDoc: 'prop.jpg', propertyDocStatus: 'PENDING'));
        }),
        const SizedBox(height: 6),
        _buildMiniSlot('4. Giấy phép KD / PCCC', _regKycDocs.businessLicense != null, () {
          setState(() => _regKycDocs = _regKycDocs.copyWith(businessLicense: 'biz.jpg', businessLicenseStatus: 'PENDING'));
        }),

        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _finalizeRegistration,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 44),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Nộp hồ sơ KYC & Hoàn tất', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: _isSubmitting ? null : _finalizeRegistration,
            child: const Text('Bỏ qua & Hoàn tất sau', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSlot(String label, bool isFilled, VoidCallback onUpload) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isFilled ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isFilled ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          InkWell(
            onTap: onUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isFilled ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                isFilled ? 'Đã tải lên ✓' : 'Tải lên +',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isFilled ? Colors.white : const Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 3. AURORA MESH CANVAS PAINTER
// ----------------------------------------------------
class _AuroraWavesPainter extends CustomPainter {
  final double animationValue;

  _AuroraWavesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * 2 * math.pi;

    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF8FAFC),
          Color(0xFFF1F5F9),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.15 + math.sin(t) * 45,
        size.height * 0.18 + math.cos(t * 0.8) * 35,
      ),
      radius: size.width * 0.45,
      color: const Color(0xFF38BDF8),
      opacity: 0.16 + math.sin(t) * 0.03,
    );

    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.88 + math.cos(t * 0.9) * 40,
        size.height * 0.28 + math.sin(t * 1.1) * 30,
      ),
      radius: size.width * 0.40,
      color: const Color(0xFF818CF8),
      opacity: 0.14 + math.cos(t * 0.03),
    );

    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.82 + math.sin(t * 1.2) * 50,
        size.height * 0.80 + math.cos(t * 0.7) * 40,
      ),
      radius: size.width * 0.50,
      color: const Color(0xFFFBBF24),
      opacity: 0.15 + math.sin(t * 0.8) * 0.03,
    );
  }

  void _drawOrb({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    if (radius <= 0) return;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          color.withValues(alpha: (opacity * 0.4).clamp(0.0, 1.0)),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraWavesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
