import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform helper for detecting the current platform
class PlatformHelper {
  static bool? _isDesktop;

  /// Check if running on desktop (macOS, Windows, Linux)
  static bool get isDesktop {
    if (_isDesktop != null) return _isDesktop!;
    
    if (kIsWeb) {
      _isDesktop = false;
      return false;
    }
    
    _isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    return _isDesktop!;
  }

  /// Check if running on mobile (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    }
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check if running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Check if running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Check if running on Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// Reset cached value (for testing)
  static void reset() {
    _isDesktop = null;
  }
}
