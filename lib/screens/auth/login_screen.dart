import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animated_pressable.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  String _selectedRole = ''; // '' (role select), 'OWNER', 'TENANT'
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roomCodeController = TextEditingController(text: '101');
  bool _obscurePassword = true;
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
    _phoneController.dispose();
    _passwordController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
      if (role == 'OWNER') {
        _phoneController.text = '0901234567';
        _passwordController.text = 'smartrent123';
      } else {
        _phoneController.text = '0912345001';
        _passwordController.text = 'tenant123';
        _roomCodeController.text = '101';
      }
    });
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final roomCode = _roomCodeController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ số điện thoại và mật khẩu.');
      return;
    }

    if (_selectedRole == 'TENANT' && roomCode.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập Mã trọ / Mã phòng trọ của bạn.');
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      await auth.login(phone, password, roomCode: roomCode);
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Pure pearl white / light background
      body: Stack(
        children: [
          // 1. Dynamic Animated Aurora Mesh & Floating Waves Canvas
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Elegant Logo Card with Soft Glow Halo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft pastel ambient halo
                          Container(
                            width: 120,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFDE68A),
                                  Color(0xFFBAE6FD),
                                  Color(0xFF93C5FD),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                          // White Card with crisp REASY Logo
                          Container(
                            width: 114,
                            height: 78,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/logo.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.home_rounded, color: Color(0xFFF59E0B), size: 28),
                                      SizedBox(width: 4),
                                      Text(
                                        'REASY',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Title: Chào mừng đến REASY
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Chào mừng đến ',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFF0284C7), Color(0xFF2563EB)],
                            ).createShader(bounds),
                            child: const Text(
                              'REASY',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hệ thống quản lý phòng trọ & cư dân thông minh',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 26),

                      // Pure White Modern Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                              blurRadius: 36,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _selectedRole.isEmpty ? _buildRoleSelection() : _buildLoginForm(auth),
                      ),

                      const SizedBox(height: 22),

                      // Footer text
                      const Text(
                        '© 2026 REASY • Nền tảng quản lý phòng trọ thế hệ mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Xác nhận vai trò truy cập',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Vui lòng chọn cổng đăng nhập của bạn để tiếp tục',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        // Option 1: Chủ trọ / Quản trị
        _buildRoleButton(
          icon: Icons.admin_panel_settings_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          title: 'Chủ trọ / Quản trị',
          subtitle: 'Quản lý tòa nhà, hóa đơn, sự cố & cư dân',
          onTap: () => _selectRole('OWNER'),
        ),

        const SizedBox(height: 14),

        // Option 2: Cư dân / Người thuê
        _buildRoleButton(
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
          title: 'Cư dân / Người thuê',
          subtitle: 'Xem hóa đơn, báo sự cố & tiện ích phòng',
          onTap: () => _selectRole('TENANT'),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      scaleDown: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
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

  Widget _buildLoginForm(AuthProvider auth) {
    final isOwner = _selectedRole == 'OWNER';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Back arrow
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _selectedRole = ''),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
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
                  width: 0.8,
                ),
              ),
              child: Text(
                isOwner ? 'Chủ trọ / Quản trị' : 'Cư dân người thuê',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isOwner ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Phone Input
        const Text('Số điện thoại đăng nhập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '0901234567',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFF59E0B), width: 1.6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        const SizedBox(height: 14),

        // Room Code Input (Tenant only)
        if (!isOwner) ...[
          const Text('Mã phòng trọ của bạn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Ví dụ: 101, 202, 301...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFF64748B), size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Password Input
        const Text('Mật khẩu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF64748B),
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFF59E0B), width: 1.6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Submit Button with Morphing Animation & Success State
        AnimatedPressable(
          onTap: (auth.isLoading || auth.isLoginSuccess) ? null : _handleLogin,
          scaleDown: 0.96,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: auth.isLoginSuccess
                  ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                  : isOwner
                      ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0284C7)])
                      : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: auth.isLoginSuccess
                      ? const Color(0xFF10B981).withValues(alpha: 0.45)
                      : (isOwner ? const Color(0xFF0284C7) : const Color(0xFFF59E0B)).withValues(alpha: 0.35),
                  blurRadius: auth.isLoginSuccess ? 22 : 16,
                  spreadRadius: auth.isLoginSuccess ? 2 : 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: auth.isLoginSuccess
                    ? Row(
                        key: const ValueKey('success_state'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Đăng nhập thành công!',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      )
                    : auth.isLoading
                        ? const SizedBox(
                            key: ValueKey('loading_state'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Row(
                            key: const ValueKey('normal_state'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Đăng nhập vào hệ thống',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Demo Account Box (Clean Light Theme)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwner ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOwner ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: isOwner ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tài khoản demo sẵn:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isOwner ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isOwner
                    ? 'SĐT: 0901234567 | Mật khẩu: smartrent123'
                    : 'SĐT: 0912345001 | Pass: tenant123 | Phòng: 101',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isOwner ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter that paints vibrant yet elegant fluid aurora mesh orbs & graceful waves
/// on a pristine white backdrop.
class _AuroraWavesPainter extends CustomPainter {
  final double animationValue;

  _AuroraWavesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * 2 * math.pi;

    // 1. Base gradient wash
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

    // 2. Animated Floating Radiant Pastel Orbs
    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.15 + math.sin(t) * 45,
        size.height * 0.18 + math.cos(t * 0.8) * 35,
      ),
      radius: size.width * 0.45,
      color: const Color(0xFF38BDF8), // Sky Cyan
      opacity: 0.16 + math.sin(t) * 0.03,
    );

    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.88 + math.cos(t * 0.9) * 40,
        size.height * 0.28 + math.sin(t * 1.1) * 30,
      ),
      radius: size.width * 0.40,
      color: const Color(0xFF818CF8), // Soft Royal Indigo
      opacity: 0.14 + math.cos(t) * 0.03,
    );

    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.82 + math.sin(t * 1.2) * 50,
        size.height * 0.80 + math.cos(t * 0.7) * 40,
      ),
      radius: size.width * 0.50,
      color: const Color(0xFFFBBF24), // Sunshine Amber
      opacity: 0.15 + math.sin(t * 0.8) * 0.03,
    );

    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.10 + math.cos(t * 0.7) * 35,
        size.height * 0.82 + math.sin(t * 0.9) * 35,
      ),
      radius: size.width * 0.42,
      color: const Color(0xFF34D399), // Mint Green
      opacity: 0.12 + math.cos(t * 1.1) * 0.03,
    );

    // 3. Flowing Sinusoidal Silk Waves
    _drawFlowingWave(
      canvas: canvas,
      size: size,
      waveHeight: size.height * 0.38,
      amplitude: 28,
      frequency: 1.2,
      phase: t,
      strokeWidth: 2.0,
      gradientColors: [
        const Color(0xFF38BDF8).withValues(alpha: 0.22),
        const Color(0xFF818CF8).withValues(alpha: 0.18),
        const Color(0xFFFBBF24).withValues(alpha: 0.15),
      ],
    );

    _drawFlowingWave(
      canvas: canvas,
      size: size,
      waveHeight: size.height * 0.65,
      amplitude: 34,
      frequency: 0.9,
      phase: -t * 0.85 + 1.0,
      strokeWidth: 2.2,
      gradientColors: [
        const Color(0xFFFBBF24).withValues(alpha: 0.18),
        const Color(0xFFF472B6).withValues(alpha: 0.16),
        const Color(0xFF38BDF8).withValues(alpha: 0.15),
      ],
    );
  }

  void _drawOrb({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          color.withValues(alpha: (opacity * 0.5).clamp(0.0, 1.0)),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  void _drawFlowingWave({
    required Canvas canvas,
    required Size size,
    required double waveHeight,
    required double amplitude,
    required double frequency,
    required double phase,
    required double strokeWidth,
    required List<Color> gradientColors,
  }) {
    final path = Path();
    final step = size.width / 40;

    path.moveTo(0, waveHeight + math.sin(phase) * amplitude);

    for (double x = 0; x <= size.width + step; x += step) {
      final normX = x / size.width;
      final y = waveHeight + math.sin(normX * frequency * 2 * math.pi + phase) * amplitude;
      path.lineTo(x, y);
    }

    final waveRect = Rect.fromLTWH(0, waveHeight - amplitude, size.width, amplitude * 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: gradientColors,
      ).createShader(waveRect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraWavesPainter oldDelegate) => true;
}
