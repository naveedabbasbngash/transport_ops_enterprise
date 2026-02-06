import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/api_endpoints.dart';

class AuthApiResponse {
  final int statusCode;
  final Map<String, dynamic> body;

  const AuthApiResponse({
    required this.statusCode,
    required this.body,
  });
}

class AuthApi {
  final http.Client _httpClient;
  final Uri _loginUri;

  AuthApi({
    http.Client? httpClient,
    Uri? loginUri,
  })  : _httpClient = httpClient ?? http.Client(),
        _loginUri = loginUri ?? Uri.parse(ApiEndpoints.authLogin);

  Future<AuthApiResponse> login({
    required String email,
    required String password,
  }) async {
    return _postLogin(
      uri: _loginUri,
      email: email,
      password: password,
    );
  }

  Future<AuthApiResponse> loginAtBaseUrl({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    return _postLogin(
      uri: uri,
      email: email,
      password: password,
    );
  }

  Future<AuthApiResponse> _postLogin({
    required Uri uri,
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final bodyString = response.body;
    Map<String, dynamic> decodedBody;
    if (bodyString.isEmpty) {
      decodedBody = <String, dynamic>{};
    } else {
      try {
        decodedBody = jsonDecode(bodyString) as Map<String, dynamic>;
      } catch (_) {
        decodedBody = <String, dynamic>{
          'status': 'error',
          'code': 'AUTH_INVALID_RESPONSE',
          'message': 'Server returned a non-JSON response.',
        };
      }
    }

    return AuthApiResponse(
      statusCode: response.statusCode,
      body: decodedBody,
    );
  }
}
