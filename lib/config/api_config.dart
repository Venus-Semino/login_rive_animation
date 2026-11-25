import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => resolve(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    override: _override,
    browserHost: Uri.base.host,
  );

  static String resolve({
    required bool isWeb,
    required TargetPlatform platform,
    String override = '',
    String browserHost = 'localhost',
  }) {
    final value = override.isNotEmpty
        ? override
        : Uri(
            scheme: 'http',
            host: isWeb
                ? (browserHost.isEmpty ? 'localhost' : browserHost)
                : platform == TargetPlatform.android
                ? '10.0.2.2'
                : 'localhost',
            port: 8080,
          ).toString();
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'API_BASE_URL debe ser una URL HTTP o HTTPS sin credenciales.',
      );
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
