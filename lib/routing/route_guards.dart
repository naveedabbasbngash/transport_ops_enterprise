import '../features/auth/presentation/auth_state.dart';

class RouteGuards {
  static bool isAuthenticated(AuthState authState) {
    return authState.user != null;
  }
}