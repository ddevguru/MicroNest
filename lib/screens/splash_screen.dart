import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/profile_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _starController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _starAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _starController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();
    _slideController.forward();
    _starController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    
    // Check if user is already logged in
    await Future.delayed(const Duration(seconds: 3)); // Show splash for 3 seconds
    
    if (mounted) {
      await _checkAuthenticationAndNavigate();
    }
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (!isLoggedIn) {
        // User not logged in, go to onboarding
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/video');
        }
        return;
      }
      
      // User is logged in, check if biometric authentication is enabled
      final isBiometricEnabled = await BiometricService.isBiometricEnabled();
      
      if (isBiometricEnabled) {
        // Check if biometric authentication is available
        final isBiometricAvailable = await BiometricService.isBiometricAvailable();
        
        if (isBiometricAvailable) {
          // Redirect to biometric lock screen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/biometric_lock');
          }
        } else {
          // Biometric not available but enabled, go to home (maybe show warning)
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication is enabled but not available on this device'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Check if PIN is enabled
        final isPinEnabled = await ProfileService.isPinSet();
        
        if (isPinEnabled) {
          // Redirect to PIN lock screen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/pin_lock');
          }
        } else {
          // No authentication required, go directly to home
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } catch (e) {
      // Error occurred, go to login to be safe
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _starController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1B4332), // Dark forest green
              Color(0xFF081C15), // Very dark green
              Color(0xFF000000), // Black
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background with organic shapes and flowing elements
            _buildBackground(),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // μN Icon with enhanced glassmorphism effect and loading states
                              _glowAnimation != null ? AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF40916C).withOpacity(0.3),
                                          const Color(0xFF2D6A4F).withOpacity(0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFF52B788).withOpacity(0.4),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF40916C).withOpacity(0.4 + (_glowAnimation.value * 0.3)),
                                          blurRadius: 30 + (_glowAnimation.value * 20),
                                          spreadRadius: 5 + (_glowAnimation.value * 5),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'μN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Color(0xFF40916C),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ) : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF40916C).withOpacity(0.3),
                                      const Color(0xFF2D6A4F).withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF52B788).withOpacity(0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF40916C).withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'μN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFF40916C),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // MicroNest Title with enhanced styling
                              const Text(
                                'MicroNest',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFF40916C),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Enhanced underline with flowing animation
                              AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 100 + (_glowAnimation.value * 20),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF52B788),
                                          Color(0xFF40916C),
                                          Color(0xFF2D6A4F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF52B788).withOpacity(0.6 + (_glowAnimation.value * 0.4)),
                                          blurRadius: 15 + (_glowAnimation.value * 10),
                                          spreadRadius: 3 + (_glowAnimation.value * 2),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Tagline with improved styling
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Building community wealth,\none contribution at a time',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF95D5B2).withOpacity(0.9),
                                    fontSize: 18,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _starAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(_starAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    paint.color = const Color(0xFF2D6A4F).withOpacity(0.1);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    
    // Draw flowing organic curves
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.3, 
      size.height * 0.1 + (math.sin(animationValue * 2 * math.pi) * 50),
      size.width * 0.7, 
      size.height * 0.4
    );
    path1.quadraticBezierTo(
      size.width * 0.9, 
      size.height * 0.6 + (math.cos(animationValue * 2 * math.pi) * 30),
      size.width, 
      size.height * 0.8
    );
    canvas.drawPath(path1, paint);
    
    // Second flowing curve
    paint.color = const Color(0xFF40916C).withOpacity(0.08);
    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.2);
    path2.quadraticBezierTo(
      size.width * 0.6, 
      size.height * 0.5 + (math.sin(animationValue * 2 * math.pi + 1) * 40),
      size.width * 0.2, 
      size.height * 0.7
    );
    path2.quadraticBezierTo(
      size.width * 0.1, 
      size.height * 0.9 + (math.cos(animationValue * 2 * math.pi + 1) * 20),
      0, 
      size.height
    );
    canvas.drawPath(path2, paint);
    
    final starColors = [
      const Color(0xFF52B788),
      const Color(0xFF40916C),
      const Color(0xFF95D5B2),
    ];
    
    for (int i = 0; i < 25; i++) {
      final x = (i * 41.0) % size.width;
      final y = (i * 67.0) % size.height;
      final colorIndex = i % starColors.length;
      final baseOpacity = 0.2 + (0.3 * math.sin(animationValue * 2 * math.pi + i.toDouble()));
      final starSize = 1.5 + (baseOpacity * 2.5);
      paint.color = starColors[colorIndex].withOpacity(baseOpacity);
      paint.style = PaintingStyle.fill;
      
      // Draw star shape
      final starPath = Path();
      final centerX = x;
      final centerY = y;
      final outerRadius = size;
      final innerRadius = size * 0.4;
      
      for (int j = 0; j < 8; j++) {
        final angle = (j * math.pi / 4);
        final radius = j % 2 == 0 ? starSize : starSize * 0.4;
        final pointX = centerX + radius * math.cos(angle);
        final pointY = centerY + radius * math.sin(angle);

        if (j == 0) {
          starPath.moveTo(pointX, pointY);
        } else {
          starPath.lineTo(pointX, pointY);
        }
      }
      starPath.close();
      
      canvas.drawPath(starPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
