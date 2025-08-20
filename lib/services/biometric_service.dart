import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  
  // Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;
      
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;
      
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }
  
  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }
  
  // Get human-readable biometric types
  static String getBiometricTypesText(List<BiometricType> types) {
    if (types.isEmpty) return 'None';
    
    List<String> typeNames = [];
    for (var type in types) {
      switch (type) {
        case BiometricType.face:
          typeNames.add('Face ID');
          break;
        case BiometricType.fingerprint:
          typeNames.add('Fingerprint');
          break;
        case BiometricType.iris:
          typeNames.add('Iris');
          break;
        case BiometricType.weak:
          typeNames.add('Pattern/PIN');
          break;
        case BiometricType.strong:
          typeNames.add('Strong Biometric');
          break;
      }
    }
    return typeNames.join(', ');
  }
  
  // Authenticate with biometrics
  static Future<BiometricResult> authenticate({
    String reason = 'Please authenticate to access the app',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult(
          success: false,
          error: 'Biometric authentication is not available on this device',
          errorType: BiometricErrorType.notAvailable,
        );
      }
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow both biometric and device credentials
        ),
      );
      
      return BiometricResult(
        success: didAuthenticate,
        error: didAuthenticate ? null : 'Authentication failed',
        errorType: didAuthenticate ? null : BiometricErrorType.userCancel,
      );
      
    } on PlatformException catch (e) {
      String errorMessage;
      BiometricErrorType errorType;
      
      switch (e.code) {
        case auth_error.notAvailable:
          errorMessage = 'Biometric authentication is not available';
          errorType = BiometricErrorType.notAvailable;
          break;
        case auth_error.notEnrolled:
          errorMessage = 'No biometrics enrolled. Please set up biometric authentication in device settings.';
          errorType = BiometricErrorType.notEnrolled;
          break;
        case auth_error.lockedOut:
          errorMessage = 'Biometric authentication is locked. Please try again later.';
          errorType = BiometricErrorType.lockedOut;
          break;
        case auth_error.permanentlyLockedOut:
          errorMessage = 'Biometric authentication is permanently locked. Please use device PIN/password.';
          errorType = BiometricErrorType.permanentlyLockedOut;
          break;
        case auth_error.biometricOnlyNotSupported:
          errorMessage = 'Biometric-only authentication is not supported';
          errorType = BiometricErrorType.notSupported;
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
          errorType = BiometricErrorType.unknown;
      }
      
      return BiometricResult(
        success: false,
        error: errorMessage,
        errorType: errorType,
      );
    } catch (e) {
      return BiometricResult(
        success: false,
        error: 'Unexpected error: $e',
        errorType: BiometricErrorType.unknown,
      );
    }
  }
  
  // Save biometric setting preference
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }
  
  // Get biometric setting preference
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
  
  // Prompt user to enable biometric authentication
  static Future<BiometricSetupResult> promptBiometricSetup() async {
    final bool isAvailable = await isBiometricAvailable();
    if (!isAvailable) {
      return BiometricSetupResult(
        success: false,
        shouldShowSettings: true,
        message: 'Biometric authentication is not available. Please set up biometric authentication in device settings.',
      );
    }
    
    final List<BiometricType> availableTypes = await getAvailableBiometrics();
    if (availableTypes.isEmpty) {
      return BiometricSetupResult(
        success: false,
        shouldShowSettings: true,
        message: 'No biometric authentication methods are enrolled. Please set up biometric authentication in device settings.',
      );
    }
    
    return BiometricSetupResult(
      success: true,
      shouldShowSettings: false,
      message: 'Biometric authentication is available: ${getBiometricTypesText(availableTypes)}',
    );
  }
}

class BiometricResult {
  final bool success;
  final String? error;
  final BiometricErrorType? errorType;
  
  BiometricResult({
    required this.success,
    this.error,
    this.errorType,
  });
}

class BiometricSetupResult {
  final bool success;
  final bool shouldShowSettings;
  final String message;
  
  BiometricSetupResult({
    required this.success,
    required this.shouldShowSettings,
    required this.message,
  });
}

enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  notSupported,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  unknown,
} 