import 'package:flutter_riverpod/legacy.dart';
import '../../../shared/providers/auth_provider.dart';
import '../data/auth_local_source.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import 'auth_state.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel({
    required this.loginUseCase,
    required this.authRepository,
  }) : super(AuthState.initial()) {
    _restoreSession();
  }

  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;

  Future<void> _restoreSession() async {
    try {
      final session = await AuthLocalSource.getSession();
      if (session == null) {
        state = state.copyWith(isBootstrapping: false);
        return;
      }

      state = state.copyWith(
        isBootstrapping: false,
        user: session.user,
        error: null,
        fieldErrors: const <String, String>{},
      );
    } catch (_) {
      state = state.copyWith(isBootstrapping: false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isBootstrapping: false,
      error: null,
      fieldErrors: const <String, String>{},
    );

    try {
      final result = await loginUseCase(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        isBootstrapping: false,
        user: result.user,
        error: null,
        fieldErrors: const <String, String>{},
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        isBootstrapping: false,
        error: e.message,
        fieldErrors: e.fieldErrors,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isBootstrapping: false,
        error: 'Unable to login right now. Please try again.',
        fieldErrors: const <String, String>{},
      );
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    state = const AuthState(
      isLoading: false,
      isBootstrapping: false,
    );
  }
}

final authViewModelProvider =
StateNotifierProvider<AuthViewModel, AuthState>(
      (ref) => AuthViewModel(
    loginUseCase: ref.watch(loginUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  ),
);
