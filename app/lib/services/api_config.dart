import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _storageKey = 'server_url';
  static const String defaultBaseUrl = 'http://localhost:8080';

  static String baseUrl = defaultBaseUrl;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null && saved.trim().isNotEmpty) {
      baseUrl = normalize(saved);
    }
  }

  static Future<void> save(String url) async {
    baseUrl = normalize(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, baseUrl);
  }

  static String normalize(String input) {
    var url = input.trim();
    if (url.isEmpty) {
      return defaultBaseUrl;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
