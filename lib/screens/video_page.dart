import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
    _initializeVideo();
  }



  void _startAnimations() async {
    _glowController.repeat(reverse: true);
  }

  Future<void> _initializeVideo() async {
    try {
      print('Starting video initialization...');
      
      // Try to load the video file
      _videoController = VideoPlayerController.asset('assets/videos/story1.mp4');
      print('Video controller created for asset: assets/videos/story1.mp4');
      
      // Initialize the video controller
      print('Initializing video controller...');
      await _videoController!.initialize();
      print('Video controller initialized successfully');
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });
        print('Video initialized state set to true');
        
        // Start playing the video
        print('Starting video playback...');
        await _videoController!.play();
        print('Video playback started');
        
        if (mounted) {
          setState(() {
            _isVideoPlaying = true;
          });
          print('Video playing state set to true');
          
          // Listen for video completion and state changes
          _videoController!.addListener(() {
            if (_videoController!.value.position >= _videoController!.value.duration) {
              print('Video completed, navigating to onboarding');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/onboarding');
              }
            }
            // Update UI when video state changes
            if (mounted) {
              setState(() {});
            }
          });
        }
      }
    } catch (e, stackTrace) {
      print('Video initialization failed with error: $e');
      print('Stack trace: $stackTrace');
      
      // Show placeholder instead of error
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });
        print('Showing placeholder due to video loading failure');
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _videoController?.dispose();
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
                  // Skip button at top right
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/onboarding');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text(
                            'Skip Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Video Container
                          Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.width * 0.6,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: _hasVideoError
                                    ? _buildErrorState()
                                    : _isVideoInitialized
                                        ? _buildVideoPlayer()
                                        : _buildLoadingState(),
                              ),
                            ),
                          ),
                          

                        ],
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

  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.6, // Reduced height to prevent stretching
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          
          // Simple play button overlay (only show if video is not playing)
          if (!_videoController!.value.isPlaying)
            GestureDetector(
              onTap: () {
                _videoController!.play();
                setState(() {});
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
        ],
      );
    } else {
      return _buildPlaceholderVideo();
    }
  }

  Widget _buildPlaceholderVideo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF52B788).withOpacity(0.4),
              width: 2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Color(0xFF52B788),
              size: 60,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'MicroNest Experience',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Building community wealth,\none contribution at a time',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF95D5B2),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/onboarding');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF52B788),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Continue to Onboarding',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.play_circle_filled,
          color: Color(0xFF52B788),
          size: 80,
        ),
        SizedBox(height: 16),
        Text(
          'Loading Video...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please wait while we prepare\nyour MicroNest experience',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF95D5B2),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: const Color(0xFFE57373),
          size: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          'Video Loading Failed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unable to load the video.\nPlease try again or skip to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF95D5B2),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE57373).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'Debug: Check console for error details\nPath: assets/videos/story1.mp4',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE57373),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasVideoError = false;
                });
                _initializeVideo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/onboarding');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Color(0xFF95D5B2),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(_glowAnimation.value),
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