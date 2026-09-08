import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/network_provider.dart';
import '../../../app/providers/storage_providers.dart';
import '../domain/auth_repository.dart';
import 'auth_api.dart';
import 'auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(AuthApi(dio), storage);
});
