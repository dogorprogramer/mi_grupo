import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const AppException(
        AppErrorType.timeout,
        'La conexión ha excedido el tiempo de espera.',
      );
    case DioExceptionType.connectionError:
      return const AppException(
        AppErrorType.network,
        'No se pudo conectar con el servidor.',
      );
    case DioExceptionType.badResponse:
      return _mapStatus(e.response?.statusCode);
    case DioExceptionType.badCertificate:
      return const AppException(
        AppErrorType.network,
        'Error de seguridad en la conexión.',
      );
    case DioExceptionType.cancel:
      return const AppException(
        AppErrorType.unexpected,
        'La petición fue cancelada.',
      );
    case DioExceptionType.unknown:
      return const AppException(
        AppErrorType.unexpected,
        'Ocurrió un error inesperado.',
      );
  }
}

AppException _mapStatus(int? statusCode) {
  if (statusCode == null) {
    return const AppException(
      AppErrorType.unexpected,
      'Ocurrió un error desconocido.',
    );
  }

  switch (statusCode) {
    case 401:
      return const AppException(
        AppErrorType.unauthorized,
        'No autorizado. Verifica tus credenciales.',
      );
    case 404:
      return const AppException(
        AppErrorType.notFound,
        'El recurso solicitado no existe.',
      );
    case 400:
      return const AppException(
        AppErrorType.badRequest,
        'La solicitud no es válida.',
      );
    case >= 500:
      return const AppException(
        AppErrorType.server,
        'Ocurrió un error en el servidor.',
      );
    default:
      return AppException(
        AppErrorType.unexpected,
        'Ocurrió un error ($statusCode).',
      );
  }
}
