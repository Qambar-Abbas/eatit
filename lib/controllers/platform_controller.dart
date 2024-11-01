import 'package:flutter/foundation.dart';
import 'dart:io' show Platform; // Show directive restricts import to only 'Platform'
import 'package:package_info_plus/package_info_plus.dart';

class PlatformController {
  final bool isWeb;
  final bool isAndroid;
  final bool isIOS;
  final bool isDesktop;

  PlatformController()
      : isWeb = kIsWeb,
        isAndroid = !kIsWeb && _isPlatform('android'),
        isIOS = !kIsWeb && _isPlatform('ios'),
        isDesktop = !kIsWeb && (_isPlatform('windows') || _isPlatform('macos') || _isPlatform('linux'));

  /// Method to detect platform type safely
  static bool _isPlatform(String platform) {
    try {
      if (platform == 'android') return Platform.isAndroid;
      if (platform == 'ios') return Platform.isIOS;
      if (platform == 'windows') return Platform.isWindows;
      if (platform == 'macos') return Platform.isMacOS;
      if (platform == 'linux') return Platform.isLinux;
    } catch (e) {
      return false; // Default to false on unsupported platforms (like web)
    }
    return false;
  }

  /// Returns a readable name for the current platform
  String getPlatformName() {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isDesktop) return 'Desktop';
    return 'Unknown';
  }

  /// Fetches the application version and build number
  Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}.${packageInfo.buildNumber}';
    } catch (e) {
      return 'Version info not available';
    }
  }
}
