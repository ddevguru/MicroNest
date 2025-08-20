import 'package:flutter/material.dart';
import '../services/test_service.dart';

class TestBackendScreen extends StatefulWidget {
  const TestBackendScreen({Key? key}) : super(key: key);

  @override
  State<TestBackendScreen> createState() => _TestBackendScreenState();
}

class _TestBackendScreenState extends State<TestBackendScreen> {
  String _testResult = 'Click a test button to start testing...';
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = 'test@example.com';
    _otpController.text = '123456';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Backend Connectivity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email for OTP Test',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'OTP for Verification Test',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testBackend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Basic Backend'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Send OTP'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Verify OTP'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testMainApi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Main API'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Results:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _testResult,
                        style: const TextStyle(fontSize: 14),
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

  Future<void> _testBackend() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing basic backend connectivity...';
    });

    try {
      final result = await TestService.testBackend();
      setState(() {
        _testResult = 'Basic Backend Test Result:\n${_formatResult(result)}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error testing backend: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSendOtp() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _testResult = 'Please enter an email address first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Testing OTP send functionality...';
    });

    try {
      final result = await TestService.testSendOtp(_emailController.text);
      setState(() {
        _testResult = 'Send OTP Test Result:\n${_formatResult(result)}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error testing OTP send: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testVerifyOtp() async {
    if (_emailController.text.isEmpty || _otpController.text.isEmpty) {
      setState(() {
        _testResult = 'Please enter both email and OTP first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Testing OTP verification functionality...';
    });

    try {
      final result = await TestService.testVerifyOtp(
        _emailController.text,
        _otpController.text,
      );
      setState(() {
        _testResult = 'Verify OTP Test Result:\n${_formatResult(result)}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error testing OTP verification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testMainApi() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing main API endpoints...';
    });

    try {
      final result = await TestService.testMainApi();
      setState(() {
        _testResult = 'Main API Test Result:\n${_formatResult(result)}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error testing main API: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatResult(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    result.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('$key:');
        value.forEach((k, v) {
          buffer.writeln('  $k: $v');
        });
      } else {
        buffer.writeln('$key: $value');
      }
    });
    return buffer.toString();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }
} 