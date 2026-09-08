enum AppErrorType {
  network,
  timeout,
  unauthorized,
  notFound,
  badRequest,
  server,
  unexpected,
}

class AppException implements Exception {
  const AppException(this.type, this.message);

  final AppErrorType type;
  final String message;

  @override
  String toString() => 'AppException($type): $message';
}
