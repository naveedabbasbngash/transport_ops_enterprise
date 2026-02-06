import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiHealthCheck {
  ApiHealthCheck._();

  static Future<String?> detectWorkingBaseUrl(
    List<String> candidates, {
    http.Client? httpClient,
  }) async {
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;
    final client = httpClient ?? http.Client();
    try {
      for (final baseUrl in candidates) {
        final uri = Uri.parse('$baseUrl/ping');
        try {
          final response = await client.get(uri);
          if (response.statusCode < 200 || response.statusCode >= 300) {
            continue;
          }
          if (response.body.isEmpty) return baseUrl;
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map &&
                decoded['status'] == 'success' &&
                decoded['code'] == 'PING_OK') {
              return baseUrl;
            }
          } catch (_) {
            continue;
          }
        } catch (_) {
          continue;
        }
      }
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
    return null;
  }
}
