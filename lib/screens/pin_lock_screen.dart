import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  
  const PinLockScreen({
    Key? key,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  final List<String> _pinDigits = [];
  final int _maxPinLength = 4;
  bool _isVerifying = false;
  String _statusMessage = 'Enter your 4-digit PIN';
  int _attempts = 0;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _addDigit(String digit) {
    if (_pinDigits.length < _maxPinLength) {
      setState(() {
        _pinDigits.add(digit);
      });
      
      // Auto-verify when 4 digits are entered
      if (_pinDigits.length == _maxPinLength) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (_pinDigits.isNotEmpty) {
      setState(() {
        _pinDigits.removeLast();
      });
    }
  }

  void _clearPin() {
    setState(() {
      _pinDigits.clear();
    });
  }

  Future<void> _verifyPin() async {
    if (_isVerifying) return;
    
    setState(() {
      _isVerifying = true;
    });

    try {
      final pin = _pinDigits.join();
      final result = await ProfileService.verifyPin(pin);
      
      if (result) {
        // PIN correct
        setState(() {
          _statusMessage = 'PIN verified successfully!';
        });
        
        // Add a small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          widget.onSuccess();
        }
      } else {
        // PIN incorrect
        _attempts++;
        if (_attempts >= _maxAttempts) {
          setState(() {
            _statusMessage = 'Too many failed attempts. Please try again later.';
          });
          _showLogoutOption();
        } else {
          setState(() {
            _statusMessage = 'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.';
          });
          await _shakeController.forward();
          await _shakeController.reverse();
          _clearPin();
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error verifying PIN: $e';
      });
      await _shakeController.forward();
      await _shakeController.reverse();
    }

    setState(() {
      _isVerifying = false;
    });
  }

  void _showLogoutOption() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'PIN Locked',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Too many failed PIN attempts. Would you like to logout and login with different credentials?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset attempts and allow retry
                setState(() {
                  _attempts = 0;
                  _statusMessage = 'Enter your 4-digit PIN';
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
                    'PIN Authentication Required',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // PIN display
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF52B788),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_maxPinLength, (index) {
                              return Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index < _pinDigits.length
                                      ? const Color(0xFF52B788)
                                      : Colors.white.withOpacity(0.3),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    },
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
                  
                  if (_isVerifying) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                    ),
                  ],
                  
                  const SizedBox(height: 60),
                  
                  // Number pad
                  Column(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (int j = 1; j <= 3; j++)
                              _buildNumberButton((i * 3 + j).toString()),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton(''),
                          _buildNumberButton('0'),
                          _buildBackspaceButton(),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Clear button
                  TextButton(
                    onPressed: _clearPin,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: Color(0xFF52B788),
                        fontSize: 16,
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

  Widget _buildNumberButton(String number) {
    if (number.isEmpty) {
      return const SizedBox(width: 80, height: 80);
    }
    
    return GestureDetector(
      onTap: () => _addDigit(number),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF52B788).withOpacity(0.2),
          border: Border.all(
            color: const Color(0xFF52B788),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _removeDigit,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withOpacity(0.2),
          border: Border.all(
            color: Colors.red,
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
} 