import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ImageService {
  // Convert image file to base64 string
  static Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  // Convert base64 string to image bytes
  static Uint8List? base64ToImageBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error converting base64 to image bytes: $e');
      return null;
    }
  }

  // Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if image file size is acceptable (default: 5MB)
  static bool isFileSizeAcceptable(File file, {double maxSizeMB = 5.0}) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }

  // Validate image file
  static bool isValidImageFile(File file) {
    final fileName = file.path.toLowerCase();
    return fileName.endsWith('.jpg') || 
           fileName.endsWith('.jpeg') || 
           fileName.endsWith('.png') || 
           fileName.endsWith('.gif');
  }

  // Get image format from file
  static String getImageFormat(File file) {
    final fileName = file.path.toLowerCase();
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'jpeg';
    } else if (fileName.endsWith('.png')) {
      return 'png';
    } else if (fileName.endsWith('.gif')) {
      return 'gif';
    }
    return 'unknown';
  }
} 