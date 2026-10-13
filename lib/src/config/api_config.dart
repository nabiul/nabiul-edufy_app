import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static String? _savedBaseUrl;

  static String get baseUrl {
    if (_savedBaseUrl?.isNotEmpty == true) return _savedBaseUrl!;
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return _trimSlash(configured);

    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return 'http://$host/nabiul-edufy/api/v1';
  }

  static void setBaseUrl(String? value) {
    final normalized = value?.trim();
    _savedBaseUrl = normalized?.isNotEmpty == true
        ? _trimSlash(normalized!)
        : null;
  }

  static String _trimSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
