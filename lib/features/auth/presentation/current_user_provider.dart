import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  return auth is AuthAuthenticated ? auth.user : null;
});
