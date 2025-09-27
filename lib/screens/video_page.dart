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
  bool _isFullScreen = true;

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
    try {
      _glowController.repeat(reverse: true);
    } catch (e) {
      // If animation fails, just stop it
      _glowController.stop();
    }
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
            _buildSafeBackground(),
            
            // Full-screen video with skip button overlay
            _isVideoInitialized && !_hasVideoError
                ? _buildFullScreenVideo()
                : _buildPlaceholderContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    return Stack(
      children: [
        // Full-screen video container
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Center(
              child: _buildVideoPlayer(),
            ),
          ),
        ),
        
        // Skip button overlay on video
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF52B788).withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/onboarding');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              ),
              child: const Text(
                'SKIP VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
        
        // Full-screen toggle button overlay
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 30,
          right: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isFullScreen = !_isFullScreen;
                });
              },
              icon: Icon(
                _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
                size: 28,
              ),
              tooltip: _isFullScreen ? 'Exit Full Screen' : 'Full Screen',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent() {
    return SafeArea(
      child: Column(
        children: [
          // Skip button at top right for placeholder content
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  ),
                  child: const Text(
                    'SKIP VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: _hasVideoError
                  ? _buildErrorState()
                  : _buildLoadingState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Full-screen video player
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          
          // Play button overlay (only show if video is not playing)
          if (!_videoController!.value.isPlaying)
            GestureDetector(
              onTap: () {
                _videoController!.play();
                setState(() {});
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 60,
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

  Widget _buildSafeBackground() {
    try {
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: BackgroundPainter(_glowAnimation.value),
            size: Size.infinite,
          );
        },
      );
    } catch (e) {
      // Fallback to simple gradient if background fails
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1B4332),
              Color(0xFF081C15),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
      );
    }
  }

  Widget _buildBackground() {
    return _buildSafeBackground();
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

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