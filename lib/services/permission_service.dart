import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return status.isGranted;
  }

  static Future<bool> requestPhotosPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        photosStatus = await Permission.photos.request();
      }
      
      if (photosStatus.isGranted) {
        return true;
      }
      
      // Fallback for older Android versions
      var storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        storageStatus = await Permission.storage.request();
      }
      
      return storageStatus.isGranted;
    } else {
      // For iOS
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        photosStatus = await Permission.photos.request();
      }
      
      return photosStatus.isGranted;
    }
  }

  static Future<bool> requestAllImagePermissions() async {
    bool cameraGranted = await requestCameraPermission();
    bool photosGranted = await requestPhotosPermission();
    
    return cameraGranted && photosGranted;
  }

  static Future<Map<String, PermissionStatus>> getPermissionStatuses() async {
    Map<String, PermissionStatus> statuses = {};
    
    statuses['camera'] = await Permission.camera.status;
    statuses['photos'] = await Permission.photos.status;
    
    if (Platform.isAndroid) {
      statuses['storage'] = await Permission.storage.status;
    }
    
    return statuses;
  }

  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      default:
        return 'Unknown';
    }
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
} 