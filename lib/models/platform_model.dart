import 'package:flutter/foundation.dart';
import 'dart:io';

class PlatformModel {
  final bool isWeb;
  final bool isAndroid;
  final bool isIOS;
  final bool isDesktop;

  PlatformModel({
    required this.isWeb,
    required this.isAndroid,
    required this.isIOS,
    required this.isDesktop,
  });

  factory PlatformModel.detectPlatform() {
    return PlatformModel(
      isWeb: kIsWeb,
      isAndroid: !kIsWeb && Platform.isAndroid,
      isIOS: !kIsWeb && Platform.isIOS,
      isDesktop: !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux),
    );
  }
}
