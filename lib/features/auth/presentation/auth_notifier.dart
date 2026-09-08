import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/auth_providers.dart';
import 'auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      final user = await ref.read(authRepositoryProvider).restoreSession();
      return user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
    } catch (_) {
      return const AuthUnauthenticated();
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      state = AsyncData(AuthAuthenticated(user));
    } catch (e) {
      state = AsyncData(AuthError(_friendlyMessage(e)));
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthUnauthenticated());
  }

  String _friendlyMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Ocurrió un error inesperado.';
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
