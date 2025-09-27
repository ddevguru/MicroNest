import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  
  const BiometricLockScreen({
    Key? key,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isAuthenticating = false;
  String _statusMessage = 'Tap to authenticate';
  IconData _lockIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricTypes();
    
    // Auto-trigger authentication after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _authenticateWithBiometrics();
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkBiometricTypes() async {
    final types = await BiometricService.getAvailableBiometrics();
    if (types.isNotEmpty) {
      setState(() {
        if (types.contains(BiometricType.face)) {
          _lockIcon = Icons.face;
        } else if (types.contains(BiometricType.fingerprint)) {
          _lockIcon = Icons.fingerprint;
        } else {
          _lockIcon = Icons.lock;
        }
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      final result = await BiometricService.authenticate(
        reason: 'Please authenticate to access MicroNest',
        useErrorDialogs: false, // We'll handle errors ourselves
      );

      if (result.success) {
        setState(() {
          _statusMessage = 'Authentication successful!';
        });
        
        // Add a small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          widget.onSuccess();
        }
      } else {
        await _handleAuthenticationError(result);
      }
    } catch (e) {
      await _handleGenericError(e.toString());
    }

    setState(() {
      _isAuthenticating = false;
    });
  }

  Future<void> _handleAuthenticationError(BiometricResult result) async {
    String message;
    bool canRetry = true;
    
    switch (result.errorType) {
      case BiometricErrorType.notAvailable:
        message = 'Biometric authentication not available';
        canRetry = false;
        break;
      case BiometricErrorType.notEnrolled:
        message = 'No biometrics enrolled. Please set up biometric authentication.';
        canRetry = false;
        break;
      case BiometricErrorType.lockedOut:
        message = 'Too many attempts. Please try again later.';
        canRetry = false;
        break;
      case BiometricErrorType.permanentlyLockedOut:
        message = 'Biometric authentication locked. Use device PIN.';
        canRetry = false;
        break;
      case BiometricErrorType.userCancel:
        message = 'Authentication cancelled. Tap to try again.';
        break;
      default:
        message = result.error ?? 'Authentication failed. Tap to try again.';
    }

    setState(() {
      _statusMessage = message;
    });

    // Trigger shake animation for failed attempts
    await _shakeController.forward();
    await _shakeController.reverse();

    // If user can't retry, show option to logout
    if (!canRetry && mounted) {
      _showLogoutOption();
    }
  }

  Future<void> _handleGenericError(String error) async {
    setState(() {
      _statusMessage = 'Error: $error';
    });

    await _shakeController.forward();
    await _shakeController.reverse();
  }

  void _showLogoutOption() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Authentication Required',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Biometric authentication is required to access the app. Would you like to logout and login with different credentials?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Try authentication again
                Future.delayed(const Duration(milliseconds: 500), () {
                  _authenticateWithBiometrics();
                });
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: Color(0xFF52B788)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Handle logout error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D3436),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo/title
                  const Text(
                    'MicroNest',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Authentication Required',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Biometric icon with animations
                  GestureDetector(
                    onTap: _isAuthenticating ? null : _authenticateWithBiometrics,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF52B788).withOpacity(0.3),
                                        const Color(0xFF52B788).withOpacity(0.1),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF52B788),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    _lockIcon,
                                    size: 50,
                                    color: const Color(0xFF52B788),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Status message
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  if (_isAuthenticating) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                    ),
                  ],
                  
                  const SizedBox(height: 60),
                  
                  // Manual authentication button
                  if (!_isAuthenticating)
                    ElevatedButton.icon(
                      onPressed: _authenticateWithBiometrics,
                      icon: const Icon(Icons.security, color: Colors.white),
                      label: const Text(
                        'Authenticate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF52B788),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 