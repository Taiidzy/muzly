import 'package:flutter/foundation.dart';

/// Logger utility for the app
/// 
/// Provides centralized logging with different severity levels
/// Logs are only printed in debug mode
class Logger {
  static const String _prefix = 'MUZLY';

  /// Log verbose information (lowest priority)
  static void v(String message, {String? tag}) {
    if (kDebugMode) {
      _log('VERBOSE', tag, message);
    }
  }

  /// Log debug information
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      _log('DEBUG', tag, message);
    }
  }

  /// Log informational messages
  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      _log('INFO', tag, message);
    }
  }

  /// Log warning messages
  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      _log('WARNING', tag, message);
    }
  }

  /// Log error messages
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _log('ERROR', tag, message);
      if (error != null) {
        debugPrint('└─ Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('└─ StackTrace: $stackTrace');
      }
    }
  }

  /// Log API request
  static void apiRequest(String method, String endpoint, {dynamic body}) {
    if (kDebugMode) {
      debugPrint('╔─ $_prefix [API] ─────────────────────────────');
      debugPrint('│ $method $endpoint');
      if (body != null) {
        debugPrint('│ Body: $body');
      }
      debugPrint('╚──────────────────────────────────────────────');
    }
  }

  /// Log API response
  static void apiResponse(String endpoint, int statusCode, {dynamic data}) {
    if (kDebugMode) {
      final statusColor = statusCode >= 200 && statusCode < 300 ? '✓' : '✗';
      debugPrint('╔─ $_prefix [API] ─────────────────────────────');
      debugPrint('│ $statusColor $endpoint - $statusCode');
      if (data != null) {
        final dataStr = data.toString();
        if (dataStr.length > 200) {
          debugPrint('│ Data: ${dataStr.substring(0, 200)}...');
        } else {
          debugPrint('│ Data: $data');
        }
      }
      debugPrint('╚──────────────────────────────────────────────');
    }
  }

  /// Log audio player state
  static void playerState(String state, {String? trackTitle, Duration? position, Duration? duration}) {
    if (kDebugMode) {
      debugPrint('╔─ $_prefix [PLAYER] ──────────────────────────');
      debugPrint('│ State: $state');
      if (trackTitle != null) {
        debugPrint('│ Track: $trackTitle');
      }
      if (position != null && duration != null) {
        debugPrint('│ Position: ${_formatDuration(position)} / ${_formatDuration(duration)}');
      }
      debugPrint('╚──────────────────────────────────────────────');
    }
  }

  /// Log navigation event
  static void navigation(String from, String to) {
    if (kDebugMode) {
      _log('NAV', 'Router', '$from -> $to');
    }
  }

  /// Internal log formatter
  static void _log(String level, String? tag, String message) {
    final tagStr = tag != null ? '[$tag]' : '';
    final timestamp = DateTime.now().toString().substring(11, 23);
    debugPrint('┌─ $_prefix [$level]$tagStr $timestamp');
    debugPrint('│ $message');
    debugPrint('└────────────────────────────────────────────────');
  }

  /// Format duration to mm:ss
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
