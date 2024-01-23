class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() {
    return 'AppException: $message';
  }
}

class DBException extends AppException {
  final String message;

  DBException(this.message) : super(message);

  @override
  String toString() {
    return 'DBException: $message';
  }
}

class ServerException extends AppException {
  final String message;

  ServerException(this.message) : super(message);

  @override
  String toString() {
    return 'ServerException: $message';
  }
}