import 'package:flutter/material.dart';
import 'dart:math' as math;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _starController;
  late Animation<double> _glowAnimation;
  late Animation<double> _starAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isEmailSent = true;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to ${_emailController.text}'),
          backgroundColor: const Color(0xFF52B788),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
                    const SizedBox(height: 60),
                    
                    // μN Icon with enhanced glassmorphism effect
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF40916C).withOpacity(0.3),
                                const Color(0xFF2D6A4F).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
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
                                fontSize: 40,
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
                    
                    const SizedBox(height: 40),
                    
                    // Title
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
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
                    
                    // Subtitle
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password',
                      style: TextStyle(
                        color: const Color(0xFF95D5B2).withOpacity(0.9),
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Success Message
                    if (_isEmailSent)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF52B788).withOpacity(0.2),
                              const Color(0xFF40916C).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF52B788),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF52B788),
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email Sent!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Check your email for password reset instructions',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (_isEmailSent) const SizedBox(height: 30),
                    
                    // Reset Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your email address',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 24,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Reset Password Button
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
                              onPressed: _isLoading ? null : _handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isEmailSent ? 'Resend Email' : 'Reset Password',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Back to Login Option
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Remember your password? ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Back to Login',
                                  style: TextStyle(
                                    color: const Color(0xFF52B788),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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