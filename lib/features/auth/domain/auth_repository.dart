import 'user.dart';

abstract class AuthRepository {
  Future<User> login({required String username, required String password});

  Future<User?> restoreSession();

  Future<void> logout();
}
