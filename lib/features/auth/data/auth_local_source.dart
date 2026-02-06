import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/user_entity.dart';

class AuthSession {
  final String token;
  final UserEntity user;

  const AuthSession({
    required this.token,
    required this.user,
  });
}

class AuthLocalSource {
  AuthLocalSource._();

  static const _storage = FlutterSecureStorage();

  static const _kAccessToken = 'auth.access_token';
  static const _kUserId = 'auth.user.id';
  static const _kUserName = 'auth.user.name';
  static const _kUserEmail = 'auth.user.email';
  static const _kUserRole = 'auth.user.role';
  static const _kUserReadOnly = 'auth.user.is_read_only';
  static const _kCompanyId = 'auth.company.id';
  static const _kCompanyName = 'auth.company.name';
  static const _kCompanyCurrency = 'auth.company.currency';
  static const _kCompanyTimezone = 'auth.company.timezone';

  static Future<void> saveSession({
    required String token,
    required UserEntity user,
    String? companyId,
    String? companyName,
    String? companyCurrency,
    String? companyTimezone,
  }) async {
    await _storage.write(key: _kAccessToken, value: token);
    await _storage.write(key: _kUserId, value: user.id);
    await _storage.write(key: _kUserName, value: user.name);
    await _storage.write(key: _kUserEmail, value: user.email);
    await _storage.write(key: _kUserRole, value: user.role);
    await _storage.write(
      key: _kUserReadOnly,
      value: user.isReadOnly ? 'true' : 'false',
    );
    if (companyId != null) {
      await _storage.write(key: _kCompanyId, value: companyId);
    }
    if (companyName != null) {
      await _storage.write(key: _kCompanyName, value: companyName);
    }
    if (companyCurrency != null) {
      await _storage.write(key: _kCompanyCurrency, value: companyCurrency);
    }
    if (companyTimezone != null) {
      await _storage.write(key: _kCompanyTimezone, value: companyTimezone);
    }
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _kAccessToken);
  }

  static Future<AuthSession?> getSession() async {
    final token = await _storage.read(key: _kAccessToken);
    final id = await _storage.read(key: _kUserId);
    final name = await _storage.read(key: _kUserName);
    final email = await _storage.read(key: _kUserEmail);
    final role = await _storage.read(key: _kUserRole);
    final readOnly = await _storage.read(key: _kUserReadOnly);

    if (token == null ||
        id == null ||
        name == null ||
        email == null ||
        role == null) {
      return null;
    }

    return AuthSession(
      token: token,
      user: UserEntity(
        id: id,
        name: name,
        email: email,
        role: role,
        isReadOnly: readOnly == 'true',
      ),
    );
  }

  static Future<String?> getCompanyId() async {
    return _storage.read(key: _kCompanyId);
  }

  static Future<String?> getCompanyName() async {
    return _storage.read(key: _kCompanyName);
  }

  static Future<String?> getCompanyCurrency() async {
    return _storage.read(key: _kCompanyCurrency);
  }

  static Future<String?> getCompanyTimezone() async {
    return _storage.read(key: _kCompanyTimezone);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kUserName);
    await _storage.delete(key: _kUserEmail);
    await _storage.delete(key: _kUserRole);
    await _storage.delete(key: _kUserReadOnly);
    await _storage.delete(key: _kCompanyId);
    await _storage.delete(key: _kCompanyName);
    await _storage.delete(key: _kCompanyCurrency);
    await _storage.delete(key: _kCompanyTimezone);
  }
}
