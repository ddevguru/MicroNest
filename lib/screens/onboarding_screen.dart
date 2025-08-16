import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  
  AnimationController? _glowController;
  AnimationController? _starController;
  Animation<double>? _glowAnimation;
  Animation<double>? _starAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to MicroNest',
      description: 'Join a community-driven financial ecosystem where every contribution builds wealth for everyone.',
      icon: Icons.group_work,
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_xyadoh9h.json',
      color: Color(0xFF52B788),
    ),
    OnboardingPage(
      title: 'Smart Savings Groups',
      description: 'Create or join savings groups, contribute regularly, and access loans when you need them.',
      icon: Icons.savings,
      lottieUrl: 'https://assets5.lottiefiles.com/packages/lf20_49rdyysj.json',
      color: Color(0xFF40916C),
    ),
    OnboardingPage(
      title: 'AI-Powered Trust',
      description: 'Our intelligent system builds trust scores based on your contributions and community reputation.',
      icon: Icons.psychology,
      lottieUrl: 'https://assets9.lottiefiles.com/packages/lf20_xyadoh9h.json',
      color: Color(0xFF2D6A4F),
    ),
  ];

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
      parent: _glowController!,
      curve: Curves.easeInOut,
    ));

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController!,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    try {
      _glowController?.repeat(reverse: true);
      _starController?.repeat(reverse: true);
    } catch (e) {
      _glowController?.stop();
      _starController?.stop();
    }
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _starController?.dispose();
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
              child: Column(
                children: [
                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _buildPage(_pages[index]);
                      },
                    ),
                  ),
                  
                  // Page indicators and navigation
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page indicators with enhanced styling
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? _pages[index].color
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: _currentPage == index
                                    ? [
                                        BoxShadow(
                                          color: _pages[index].color.withOpacity(0.6),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : <BoxShadow>[],
                              ),
                            ),
                          ),
                        ),
                        
                        // Next/Get Started button with enhanced styling
                        _glowAnimation != null ? AnimatedBuilder(
                          animation: _glowAnimation!,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _pages[_currentPage].color,
                                    _pages[_currentPage].color.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pages[_currentPage].color.withOpacity(0.4 + (_glowAnimation!.value * 0.2)),
                                    blurRadius: 20 + (_glowAnimation!.value * 10),
                                    spreadRadius: 3 + (_glowAnimation!.value * 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_currentPage < _pages.length - 1) {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  } else {
                                    // Navigate to the second onboarding screen
                                    Navigator.pushReplacementNamed(context, '/onboarding-second');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ) : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _pages[_currentPage].color,
                                _pages[_currentPage].color.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_currentPage].color.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < _pages.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                // Navigate to the second onboarding screen
                                Navigator.pushReplacementNamed(context, '/onboarding-second');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
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
          ],
        ),
      ),
    );
  }

    Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation with enhanced glassmorphism effect
          _glowAnimation != null ? AnimatedBuilder(
            animation: _glowAnimation!,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: page.color.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.color.withOpacity(0.3 + (_glowAnimation!.value * 0.2)),
                      blurRadius: 40 + (_glowAnimation!.value * 20),
                      spreadRadius: 15 + (_glowAnimation!.value * 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: page.lottieUrl != null
                    ? Lottie.network(
                        page.lottieUrl!,
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            page.icon,
                            size: 80,
                            color: page.color,
                          );
                        },
                      )
                    : Icon(
                        page.icon,
                        size: 80,
                        color: page.color,
                      ),
              );
            },
          ) : Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.color.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: page.lottieUrl != null
                ? Lottie.network(
                    page.lottieUrl!,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        page.icon,
                        size: 80,
                        color: page.color,
                      );
                    },
                  )
                : Icon(
                    page.icon,
                    size: 80,
                    color: page.color,
                  ),
          ),
          
          const SizedBox(height: 50),
          
          // Title with enhanced styling
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Color(0xFF40916C),
                  blurRadius: 15,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Description with enhanced styling
          Text(
            page.description,
            style: TextStyle(
              fontSize: 20,
              color: const Color(0xFF95D5B2).withOpacity(0.9),
              height: 1.6,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }







  Widget _buildSafeBackground() {
    if (_starAnimation == null) {
      // Return a simple gradient background if animation is not ready
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF2D6A4F),
              Color(0xFF081C15),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _starAnimation!,
      builder: (context, child) {
        return CustomPaint(
          painter: SafeBackgroundPainter(_starAnimation!.value),
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
        final y = (i * 89.0) % (size.height - 10);
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

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final String? lottieUrl;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.lottieUrl,
    required this.color,
  });
} 