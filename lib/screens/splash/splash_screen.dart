import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final String? userName;
  final String? statusMessage;
  final VoidCallback? onFinished;

  const SplashScreen({
    super.key,
    this.userName,
    this.statusMessage,
    this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Background Aurora Waves Controller
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 2. Logo Pulse & Glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 3. Floating Motion
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutQuad),
    );

    // 4. Progress Controller (0% to 100%)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward().then((_) {
      if (mounted) {
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _getStatusText(double percent) {
    if (widget.statusMessage != null && widget.statusMessage!.isNotEmpty) {
      return widget.statusMessage!;
    }

    if (widget.userName != null) {
      if (percent < 0.28) {
        return 'Đang xác thực thông tin tài khoản...';
      } else if (percent < 0.65) {
        return 'Đang đồng bộ dữ liệu phòng & dịch vụ...';
      } else if (percent < 0.92) {
        return 'Đang chuẩn bị không gian làm việc...';
      } else {
        return 'Hoàn tất! Đang chuyển hướng...';
      }
    } else {
      if (percent < 0.35) {
        return 'Đang kiểm tra phiên làm việc...';
      } else if (percent < 0.8) {
        return 'Đang tải tài nguyên hệ thống...';
      } else {
        return 'Sẵn sàng!';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Pure clean white / light background
      body: Stack(
        children: [
          // 1. Dynamic Animated Aurora Mesh & Floating Waves Canvas (Same as Login Screen)
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

          // 2. Center Hero Logo & Info
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _floatController]),
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Glowing Logo Card
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft pastel ambient breathing halo
                            Container(
                              width: 130,
                              height: 92,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFDE68A),
                                    Color(0xFFBAE6FD),
                                    Color(0xFF93C5FD),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: _glowAnimation.value),
                                    blurRadius: 32,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFBBF24).withValues(alpha: _glowAnimation.value * 0.6),
                                    blurRadius: 24,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),

                            // White Logo Card with clean border
                            Container(
                              width: 122,
                              height: 84,
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/logo.jpg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.home_rounded, color: Color(0xFFF59E0B), size: 30),
                                        SizedBox(width: 4),
                                        Text(
                                          'REASY',
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
                      ),

                      const SizedBox(height: 24),

                      // Brand Name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFF0284C7), Color(0xFF2563EB)],
                        ).createShader(bounds),
                        child: const Text(
                          'REASY',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // User Greeting or System Slogan
                      if (widget.userName != null) ...[
                        Text(
                          'Xin chào, ${widget.userName}!',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Đang tải vào tài khoản của bạn...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Hệ thống quản lý phòng trọ thông minh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Bottom Progress Bar with Percentage Indicator
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) {
                    final progress = _progressAnimation.value;
                    final percent = (progress * 100).toInt().clamp(0, 100);
                    final status = _getStatusText(progress);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status & Percentage Text Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                              ),
                              child: Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2563EB),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Horizontal Progress Track Bar
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress.clamp(0.01, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF0284C7),
                                        Color(0xFF38BDF8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that paints vibrant yet elegant fluid aurora mesh orbs & graceful waves
/// on a pristine white backdrop matching the login screen.
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
      opacity: 0.14 + math.cos(t * 0.03),
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
