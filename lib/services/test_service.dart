import 'dart:convert';
import 'package:http/http.dart' as http;

class TestService {
  static const String baseUrl = 'http://103.120.179.212/micronest/backend';
  
  // Test basic backend connectivity
  static Future<Map<String, dynamic>> testBackend() async {
    try {
      print('Testing backend connectivity...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/test.php'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Test Response Status: ${response.statusCode}');
      print('Test Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'body': response.body
        };
      }
    } catch (e) {
      print('Test Backend Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Test OTP functionality
  static Future<Map<String, dynamic>> testSendOtp(String email) async {
    try {
      print('Testing OTP send for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/test_otp.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'action': 'send_otp',
          'email': email,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Test OTP Response Status: ${response.statusCode}');
      print('Test OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'body': response.body
        };
      }
    } catch (e) {
      print('Test OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Test OTP verification
  static Future<Map<String, dynamic>> testVerifyOtp(String email, String otp) async {
    try {
      print('Testing OTP verification for: $email with OTP: $otp');
      
      final response = await http.post(
        Uri.parse('$baseUrl/test_otp.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'action': 'verify_otp',
          'email': email,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Test Verify OTP Response Status: ${response.statusCode}');
      print('Test Verify OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'body': response.body
        };
      }
    } catch (e) {
      print('Test Verify OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Test main API endpoints
  static Future<Map<String, dynamic>> testMainApi() async {
    try {
      print('Testing main API endpoints...');
      
      // Test login endpoint
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/api_direct.php?action=login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': 'test@example.com',
          'password': 'test123',
        }),
      ).timeout(const Duration(seconds: 30));

      print('Main API Login Response Status: ${loginResponse.statusCode}');
      print('Main API Login Response Body: ${loginResponse.body}');

      return {
        'success': true,
        'message': 'Main API test completed',
        'login_status': loginResponse.statusCode,
        'login_body': loginResponse.body
      };
      
    } catch (e) {
      print('Test Main API Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
} 