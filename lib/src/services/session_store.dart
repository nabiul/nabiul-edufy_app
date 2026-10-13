import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'api_token';
  static const _apiBaseUrlKey = 'api_base_url';

  Future<String?> readToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
  }

  Future<String?> readApiBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_apiBaseUrlKey);
  }

  Future<void> saveApiBaseUrl(String url) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_apiBaseUrlKey, url);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }
}
