import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;

  final math.Random _random = math.Random();
  final List<_SplashStar> _stars = [];

  @override
  void initState() {
    super.initState();

    // Pulse & glow animation for logo halo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Floating vertical motion
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutQuad),
    );

    // Shimmer effect for progress bar and text
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Generate floating star particles
    final starColors = [
      const Color(0xFFFBD38D),
      const Color(0xFF38BDF8),
      const Color(0xFF60A5FA),
      const Color(0xFFC084FC),
      const Color(0xFFFFFFFF),
    ];

    for (int i = 0; i < 45; i++) {
      _stars.add(_SplashStar(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.5 + 1.0,
        speedY: _random.nextDouble() * 0.03 + 0.01,
        opacity: _random.nextDouble() * 0.6 + 0.2,
        color: starColors[_random.nextInt(starColors.length)],
        offset: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712), // Deep cosmic black/slate
      body: Stack(
        children: [
          // 1. Ambient Background Orbs
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Animated Starfield
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return CustomPaint(
                painter: _SplashStarfieldPainter(
                  stars: _stars,
                  animationValue: _pulseController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 3. Center Hero Logo & Animation
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _floatController, _shimmerController]),
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
                            // Ambient Breathing Halo
                            Container(
                              width: 140,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFF38BDF8),
                                    Color(0xFF2563EB),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: _glowAnimation.value),
                                    blurRadius: 36,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: _glowAnimation.value * 0.7),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),

                            // Logo Card with Border
                            Container(
                              width: 126,
                              height: 88,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
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
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.home_rounded, color: Color(0xFFF59E0B), size: 32),
                                        SizedBox(width: 4),
                                        Text(
                                          'EASY',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
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

                      const SizedBox(height: 28),

                      // Brand Name with Gradient Shimmer
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: const [
                              Color(0xFFFDE68A),
                              Color(0xFF7DD3FC),
                              Color(0xFF60A5FA),
                              Color(0xFFFDE68A),
                            ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                            transform: GradientRotation(_shimmerController.value * 2 * math.pi),
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'RENTEASY',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Slogan
                      Text(
                        'Quản lý trọ & căn hộ thông minh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Modern Glowing Pulse Dots Loader
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final delay = index * 0.25;
                          final value = (_shimmerController.value + delay) % 1.0;
                          final scale = 0.6 + 0.6 * math.sin(value * math.pi);
                          final opacity = 0.3 + 0.7 * math.sin(value * math.pi);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 10 * scale,
                            height: 10 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == 0
                                  ? const Color(0xFF38BDF8).withValues(alpha: opacity)
                                  : (index == 1
                                      ? const Color(0xFFF59E0B).withValues(alpha: opacity)
                                      : const Color(0xFF60A5FA).withValues(alpha: opacity)),
                              boxShadow: [
                                BoxShadow(
                                  color: (index == 0
                                          ? const Color(0xFF38BDF8)
                                          : (index == 1 ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA)))
                                      .withValues(alpha: opacity * 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 4. Footer info
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.0 • Nền tảng số hóa quản lý chuỗi trọ',
                style: TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashStar {
  double x;
  double y;
  final double size;
  final double speedY;
  double opacity;
  final Color color;
  final double offset;

  _SplashStar({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.opacity,
    required this.color,
    required this.offset,
  });
}

class _SplashStarfieldPainter extends CustomPainter {
  final List<_SplashStar> stars;
  final double animationValue;

  _SplashStarfieldPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final star in stars) {
      final currentY = (star.y - animationValue * star.speedY * 3) % 1.0;
      final currentX = (star.x + math.sin(animationValue * 2 * math.pi + star.offset) * 0.01) % 1.0;

      final px = currentX * size.width;
      final py = currentY * size.height;

      final pulse = (math.sin(animationValue * 4 * math.pi + star.offset) + 1) / 2;
      final currentOpacity = (star.opacity * (0.5 + 0.5 * pulse)).clamp(0.1, 1.0);

      paint.color = star.color.withValues(alpha: currentOpacity);
      canvas.drawCircle(Offset(px, py), star.size, paint);

      paint.color = star.color.withValues(alpha: currentOpacity * 0.3);
      canvas.drawCircle(Offset(px, py), star.size * 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashStarfieldPainter oldDelegate) => true;
}
