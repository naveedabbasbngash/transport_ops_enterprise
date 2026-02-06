import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiBaseUrlStore {
  ApiBaseUrlStore._();

  static const _storage = FlutterSecureStorage();
  static const _kBaseUrl = 'api.base_url';

  static Future<void> save(String baseUrl) async {
    await _storage.write(key: _kBaseUrl, value: baseUrl);
  }

  static Future<String?> get() async {
    return _storage.read(key: _kBaseUrl);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kBaseUrl);
  }
}
