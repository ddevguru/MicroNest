import 'package:flutter/material.dart';
import 'dart:math' as math;

class OnboardingSecondScreen extends StatefulWidget {
  const OnboardingSecondScreen({super.key});

  @override
  State<OnboardingSecondScreen> createState() => _OnboardingSecondScreenState();
}

class _OnboardingSecondScreenState extends State<OnboardingSecondScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _starController;
  late Animation<double> _glowAnimation;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _starController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    try {
      _glowController.repeat(reverse: true);
      _starController.repeat(reverse: true);
    } catch (e) {
      _glowController.stop();
      _starController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _starController.dispose();
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
            _buildSafeBackground(),
            
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // μN Icon with enhanced glassmorphism effect
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF40916C).withOpacity(0.3),
                                const Color(0xFF2D6A4F).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
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
                                fontSize: 32,
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
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Welcome Title
                    const Text(
                      'Welcome to MicroNest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Color(0xFF40916C),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text(
                      'Join trusted savings circles, build your financial future, and help your community grow together.',
                      style: TextStyle(
                        color: Color(0xFF95D5B2),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Feature Cards
                    _buildFeatureCard(
                      icon: Icons.group,
                      title: 'Community-driven savings',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF52B788), Color(0xFF40916C)],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureCard(
                      icon: Icons.security,
                      title: 'Blockchain-secured transactions',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureCard(
                      icon: Icons.flash_on,
                      title: 'Instant micro-loans',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Statistics Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatistic('5K+', 'Active Users'),
                        _buildStatistic('\$2M+', 'Saved Together'),
                        _buildStatistic('98%', 'Success Rate'),
                      ],
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Get Started Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF52B788), Color(0xFF40916C)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF52B788).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Login Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFF52B788),
                          width: 2,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          // Navigate to login screen
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Already have an account? Log In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF52B788),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.star_border,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF95D5B2).withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSafeBackground() {
    return AnimatedBuilder(
      animation: _starAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: SafeBackgroundPainter(_starAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class SafeBackgroundPainter extends CustomPainter {
  final double animationValue;

  SafeBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    
    final paint = Paint();
    
    // Simple gradient background instead of complex paths
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create a simple radial gradient
    final gradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.5,
      colors: [
        const Color(0xFF2D6A4F).withOpacity(0.1),
        const Color(0xFF40916C).withOpacity(0.08),
        const Color(0xFF52B788).withOpacity(0.05),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    
    // Simple animated dots instead of complex stars
    paint.shader = null;
    paint.style = PaintingStyle.fill;
    
    final dotColors = [
      const Color(0xFF52B788),
      const Color(0xFF40916C),
      const Color(0xFF95D5B2),
    ];
    
    for (int i = 0; i < 15; i++) {
      try {
        final x = (i * 67.0) % (size.width - 10);
        final y = (i * 67.0) % (size.height - 10);
        final colorIndex = i % dotColors.length;
        final opacity = 0.1 + (0.2 * (math.sin(animationValue * 2 * math.pi + i.toDouble()) + 1) / 2);
        
        paint.color = dotColors[colorIndex].withOpacity(opacity);
        
        // Draw simple circles instead of complex star shapes
        final dotSize = 2.0 + (opacity * 3.0);
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      } catch (e) {
        // Skip drawing this dot if there's an error
        continue;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 