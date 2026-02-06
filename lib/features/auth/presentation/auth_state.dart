import '../domain/entities/user_entity.dart';

class AuthState {
  static const _sentinel = Object();

  final bool isLoading;
  final bool isBootstrapping;
  final UserEntity? user;
  final String? error;
  final Map<String, String> fieldErrors;

  const AuthState({
    required this.isLoading,
    required this.isBootstrapping,
    this.user,
    this.error,
    this.fieldErrors = const {},
  });

  factory AuthState.initial() {
    return const AuthState(
      isLoading: false,
      isBootstrapping: true,
    );
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isBootstrapping,
    Object? user = _sentinel,
    Object? error = _sentinel,
    Object? fieldErrors = _sentinel,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      user: identical(user, _sentinel) ? this.user : user as UserEntity?,
      error: identical(error, _sentinel) ? this.error : error as String?,
      fieldErrors: identical(fieldErrors, _sentinel)
          ? this.fieldErrors
          : fieldErrors as Map<String, String>,
    );
  }

  @override
  String toString() {
    return 'AuthState('
        'isLoading=$isLoading, '
        'isBootstrapping=$isBootstrapping, '
        'user=${user?.name ?? 'null'}, '
        'role=${user?.role ?? 'null'}, '
        'error=$error'
        ')';
  }
}
