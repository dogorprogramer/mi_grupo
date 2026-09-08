import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_interceptor.dart';
import '../../core/network/dio_client.dart';
import 'storage_providers.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return DioClient(authInterceptor: AuthInterceptor(storage));
});

final dioProvider = Provider<Dio>((ref) => ref.watch(dioClientProvider).dio);
