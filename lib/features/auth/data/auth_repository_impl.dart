import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_api.dart';
import 'auth_local_source.dart';
import '../../../core/config/api_base_url_store.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_health_check.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;

  const AuthRepositoryImpl({required AuthApi authApi}) : _authApi = authApi;

  @override
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final cachedBaseUrl = await ApiBaseUrlStore.get();
    final detectedBaseUrl = await ApiHealthCheck.detectWorkingBaseUrl(
      Env.apiBaseUrlCandidates,
    );
    final resolvedBaseUrl = detectedBaseUrl ?? cachedBaseUrl ?? Env.apiBaseUrl;

    if (cachedBaseUrl != resolvedBaseUrl) {
      await ApiBaseUrlStore.save(resolvedBaseUrl);
    }

    final response = await _authApi.loginAtBaseUrl(
      baseUrl: resolvedBaseUrl,
      email: email,
      password: password,
    );

    final body = response.body;
    final status = (body['status'] ?? '').toString();
    final code = (body['code'] ?? '').toString();
    final message = (body['message'] ?? 'Unable to login').toString();

    if (status == 'success' && code == 'AUTH_LOGIN_SUCCESS') {
      final data =
          (body['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final token =
          (data['token'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final userMap =
          (data['user'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final company =
          (data['company'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      final accessToken = (token['access_token'] ?? '').toString();
      if (accessToken.isEmpty) {
        throw const AuthFailure(
          code: 'AUTH_INVALID_RESPONSE',
          message: 'Login response did not include an access token.',
        );
      }

      final user = UserEntity(
        id: (userMap['id'] ?? '').toString(),
        name: (userMap['name'] ?? '').toString(),
        email: (userMap['email'] ?? '').toString(),
        role: (userMap['role'] ?? '').toString(),
        isReadOnly: userMap['is_read_only'] == true,
      );

      await AuthLocalSource.saveSession(
        token: accessToken,
        user: user,
        companyId: (company['id'] ?? '').toString(),
        companyName: (company['name'] ?? '').toString(),
        companyCurrency: (company['currency'] ?? '').toString(),
        companyTimezone: (company['timezone'] ?? '').toString(),
      );

      return AuthLoginResult(
        user: user,
        accessToken: accessToken,
        tokenType: (token['token_type'] ?? 'Bearer').toString(),
        expiresIn: (token['expires_in'] is num)
            ? (token['expires_in'] as num).toInt()
            : int.tryParse((token['expires_in'] ?? '').toString()) ?? 0,
        companyId: (company['id'] ?? '').toString(),
        companyName: (company['name'] ?? '').toString(),
        companyTimezone: (company['timezone'] ?? '').toString(),
        companyCurrency: (company['currency'] ?? '').toString(),
      );
    }

    if (code == 'VALIDATION_ERROR') {
      throw AuthFailure(
        code: code,
        message: message,
        fieldErrors: _readFieldErrors(body['errors']),
      );
    }

    throw AuthFailure(code: code, message: message);
  }

  @override
  Future<void> logout() async {
    await AuthLocalSource.clear();
  }

  Map<String, String> _readFieldErrors(dynamic raw) {
    if (raw is! Map) return const {};

    final result = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is List && value.isNotEmpty) {
        result[key] = value.first.toString();
        continue;
      }
      if (value != null) {
        result[key] = value.toString();
      }
    }
    return result;
  }
}
