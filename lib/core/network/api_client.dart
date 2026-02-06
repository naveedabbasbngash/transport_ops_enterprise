import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_local_source.dart';
import '../config/api_base_url_store.dart';
import '../config/env.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? Env.apiBaseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = await _buildUri(path, query);
    log('HTTP GET $uri', name: 'ApiClient', error: query);
    return _httpClient.get(
      uri,
      headers: await _withAuthHeaders(headers),
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = await _buildUri(path);
    log('HTTP POST $uri', name: 'ApiClient', error: body);
    return _httpClient.post(
      uri,
      headers: await _withAuthHeaders(headers),
      body: body,
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };
    final response = await get(path, headers: mergedHeaders, query: query);
    return _decodeJson(response, 'GET $path');
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };
    final response = await post(
      path,
      headers: mergedHeaders,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeJson(response, 'POST $path');
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = await _buildUri(path);
    log('HTTP PUT $uri', name: 'ApiClient', error: body);
    return _httpClient.put(
      uri,
      headers: await _withAuthHeaders(headers),
      body: body,
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };
    final response = await put(
      path,
      headers: mergedHeaders,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeJson(response, 'PUT $path');
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = await _buildUri(path);
    log('HTTP DELETE $uri', name: 'ApiClient');
    return _httpClient.delete(
      uri,
      headers: await _withAuthHeaders(headers),
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };
    final response = await delete(path, headers: mergedHeaders);
    return _decodeJson(response, 'DELETE $path');
  }

  Future<http.Response> postMultipart(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = await _buildUri(path);
    final request = http.MultipartRequest('POST', uri);
    final authHeaders = await _withAuthHeaders(headers);
    request.headers.addAll(authHeaders);
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    if (files != null && files.isNotEmpty) {
      request.files.addAll(files);
    }
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  Future<Uri> _buildUri(String path, [Map<String, dynamic>? query]) async {
    final resolvedBaseUrl = await ApiBaseUrlStore.get() ?? _baseUrl;
    final uri = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.parse('$resolvedBaseUrl/$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<Map<String, String>> _withAuthHeaders(
    Map<String, String>? headers,
  ) async {
    final token = await AuthLocalSource.getToken();
    return <String, String>{
      ...?headers,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeJson(http.Response response, String context) {
    final body = response.body;
    if (body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return <String, dynamic>{'data': decoded};
    } catch (_) {
      final snippet = body
          .substring(0, math.min(220, body.length))
          .replaceAll('\n', ' ')
          .replaceAll('\r', ' ');
      log(
        'HTTP $context JSON parse failed (${response.statusCode})',
        name: 'ApiClient',
        error: snippet,
      );
      throw Exception(
        'Invalid server response (${response.statusCode}). Expected JSON. '
        'Body: $snippet',
      );
    }
  }
}
