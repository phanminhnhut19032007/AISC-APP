import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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

  late AnimationController _particleController;
  final List<_StarParticle> _stars = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate 65 background glowing stars matching the web's canvas
    final starColors = [
      const Color(0xFFFBD38D), // Amber / Gold
      const Color(0xFF38BDF8), // Sky Blue
      const Color(0xFF60A5FA), // Blue
      const Color(0xFFC084FC), // Purple
      const Color(0xFFFFFFFF), // White
    ];

    for (int i = 0; i < 65; i++) {
      _stars.add(_StarParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3.0 + 1.2,
        speedY: _random.nextDouble() * 0.04 + 0.015,
        speedX: (_random.nextDouble() - 0.5) * 0.02,
        opacity: _random.nextDouble() * 0.6 + 0.3,
        color: starColors[_random.nextInt(starColors.length)],
        pulseOffset: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
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
      backgroundColor: const Color(0xFF030712), // Slate 950 deep space
      body: Stack(
        children: [
          // 1. Cosmic Glow Orbs in background
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Animated Particle Stars Canvas
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarFieldPainter(
                  stars: _stars,
                  animationValue: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 3. Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glowing Logo Card
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft glow halo
                          Container(
                            width: 124,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFF38BDF8), Color(0xFF2563EB)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          // White Card with Logo
                          Container(
                            width: 116,
                            height: 80,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/logo.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.home_rounded, color: Color(0xFFF59E0B), size: 28),
                                      SizedBox(width: 4),
                                      Text(
                                        'EASY',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
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
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFDE68A), Color(0xFF7DD3FC), Color(0xFF60A5FA)],
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

                      const SizedBox(height: 28),

                      // Glassmorphic Login Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 36,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: _selectedRole.isEmpty ? _buildRoleSelection() : _buildLoginForm(auth),
                      ),

                      const SizedBox(height: 24),

                      // Footer text
                      const Text(
                        '© 2026 REASY • Nền tảng quản lý phòng trọ thế hệ mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Vui lòng chọn cổng đăng nhập của bạn để tiếp tục',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 20),

        // Option 1: Chủ trọ / Quản trị
        _buildRoleButton(
          icon: Icons.person_outline_rounded,
          iconColor: const Color(0xFF38BDF8),
          iconBgColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
          hoverBorderColor: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          title: 'Chủ trọ / Quản trị',
          onTap: () => _selectRole('OWNER'),
        ),

        const SizedBox(height: 14),

        // Option 2: Cư dân / Người thuê
        _buildRoleButton(
          icon: Icons.people_outline_rounded,
          iconColor: const Color(0xFFFBBF24),
          iconBgColor: const Color(0xFFD97706).withValues(alpha: 0.25),
          hoverBorderColor: const Color(0xFFFBBF24).withValues(alpha: 0.4),
          title: 'Cư dân / Người thuê',
          onTap: () => _selectRole('TENANT'),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color hoverBorderColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      scaleDown: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hoverBorderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF64748B)),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF94A3B8)),
              ),
            ),
            Text(
              'Đăng nhập: ${isOwner ? "Chủ trọ / Quản trị" : "Cư dân người thuê"}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isOwner ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Phone Input
        const Text('Số điện thoại đăng nhập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1))),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '0901234567',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        const SizedBox(height: 14),

        // Room Code Input (Tenant only)
        if (!isOwner) ...[
          const Text('Mã phòng trọ của bạn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1))),
          const SizedBox(height: 6),
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ví dụ: 101, 202, 301...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFF94A3B8), size: 18),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Password Input
        const Text('Mật khẩu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1))),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isOwner ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Submit Button
        AnimatedPressable(
          onTap: auth.isLoading ? null : _handleLogin,
          scaleDown: 0.96,
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: isOwner
                  ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0284C7)])
                  : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isOwner ? const Color(0xFF0284C7) : const Color(0xFFF59E0B)).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đăng nhập vào hệ thống',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isOwner ? Colors.white : const Color(0xFF030712),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: isOwner ? Colors.white : const Color(0xFF030712)),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Demo Account Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💡 Tài khoản demo sẵn:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 4),
              Text(
                isOwner
                    ? 'SĐT: 0901234567 | Mật khẩu: smartrent123'
                    : 'SĐT: 0912345001 | Pass: tenant123 | Phòng: 101',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarParticle {
  double x;
  double y;
  final double size;
  final double speedY;
  final double speedX;
  double opacity;
  final Color color;
  final double pulseOffset;

  _StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.opacity,
    required this.color,
    required this.pulseOffset,
  });
}

class _StarFieldPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double animationValue;

  _StarFieldPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final star in stars) {
      // Calculate animated position
      final currentY = (star.y - animationValue * star.speedY * 5) % 1.0;
      final currentX = (star.x + math.sin(animationValue * 2 * math.pi + star.pulseOffset) * 0.015) % 1.0;

      final px = currentX * size.width;
      final py = currentY * size.height;

      final pulse = (math.sin(animationValue * 4 * math.pi + star.pulseOffset) + 1) / 2;
      final currentOpacity = (star.opacity * (0.6 + 0.4 * pulse)).clamp(0.1, 1.0);

      paint.color = star.color.withValues(alpha: currentOpacity);
      canvas.drawCircle(Offset(px, py), star.size, paint);

      // Glow halo
      paint.color = star.color.withValues(alpha: currentOpacity * 0.35);
      canvas.drawCircle(Offset(px, py), star.size * 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => true;
}
