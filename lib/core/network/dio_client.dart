import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

class DioClient {
  DioClient({Interceptor? authInterceptor})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            sendTimeout: AppConstants.sendTimeout,
          ),
        ) {
    if (authInterceptor != null) {
      dio.interceptors.add(authInterceptor);
    }
  }

  final Dio dio;
}
