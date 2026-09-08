import '../domain/user.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
