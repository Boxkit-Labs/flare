import 'package:dio/dio.dart';

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'No Internet Connection', dynamic originalError])
      : super(message, originalError: originalError);
}

class ServerException extends AppException {
  ServerException([String message = 'Server Error', dynamic originalError])
      : super(message, originalError: originalError);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized', dynamic originalError])
      : super(message, originalError: originalError);
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Not Found', dynamic originalError])
      : super(message, originalError: originalError);
}

class ValidationException extends AppException {
  ValidationException([String message = 'Invalid Request', dynamic originalError])
      : super(message, originalError: originalError);
}

class RateLimitException extends AppException {
  RateLimitException([String message = 'Too many requests. Please slow down.', dynamic originalError])
      : super(message, originalError: originalError);
}

class UnknownException extends AppException {
  UnknownException([String message = 'An unexpected error occurred', dynamic originalError])
      : super(message, originalError: originalError);
}

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkException('The server is taking too long to respond. Please try again.', e);
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return UnauthorizedException('Your session has expired. Please log in again.', e);
      } else if (statusCode == 404) {
        return NotFoundException('The requested resource was not found.', e);
      } else if (statusCode == 429) {
        return RateLimitException('You are being rate limited. Please wait a moment and try again.', e);
      } else if (statusCode != null && statusCode >= 500) {
        return ServerException('Our servers are experiencing a temporary hiccup. Please try again later.', e);
      } else if (statusCode == 400) {
        return ValidationException('There was a problem with your request. Please check your data and try again.', e);
      }
      return UnknownException('Server returned an unexpected error ($statusCode).', e);
    case DioExceptionType.cancel:
      return UnknownException('Request was cancelled.', e);
    default:
      if (e.error != null && e.error.toString().contains('SocketException')) {
        return NetworkException('No Internet connection. Please check your network settings.', e);
      }
      return UnknownException('Something went wrong. Please try again.', e);
  }
}
