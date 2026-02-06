import '../entities/user_entity.dart';

class AuthLoginResult {
  final UserEntity user;
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String companyId;
  final String companyName;
  final String companyTimezone;
  final String companyCurrency;

  const AuthLoginResult({
    required this.user,
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.companyId,
    required this.companyName,
    required this.companyTimezone,
    required this.companyCurrency,
  });
}

class AuthFailure implements Exception {
  final String code;
  final String message;
  final Map<String, String> fieldErrors;

  const AuthFailure({
    required this.code,
    required this.message,
    this.fieldErrors = const {},
  });
}

abstract class AuthRepository {
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}
