import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PlatformService {
  static String getPlatform() {
    if (kIsWeb) {
      return 'Web';
    }
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      return 'Unknown';
    } catch (e) {
      print('Error detecting platform: $e');
      return 'Unknown';
    }
  }

  static String _appVersion = 'Unavailable';
  static Future<void> initializeAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (e) {
      print('Error retrieving app version: $e');
      _appVersion = 'Unavailable';
    }
  }

  static String getAppVersion() {
    return _appVersion;
  }
}
