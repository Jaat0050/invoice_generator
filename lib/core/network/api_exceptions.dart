import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final resData = error.response?.data;
        String msg = 'An unexpected server error occurred.';
        if (resData is Map<String, dynamic> && resData.containsKey('message')) {
          msg = resData['message'].toString();
        } else if (status == 401) {
          msg = 'Session expired. Please log in again.';
        } else if (status == 403) {
          msg = 'Access denied. You do not have permission.';
        } else if (status == 404) {
          msg = 'Requested resource not found.';
        } else if (status == 422) {
          if (resData is Map && resData['errors'] is Map) {
            final errors = (resData['errors'] as Map).values.expand((e) => e is List ? e : [e]).toList();
            msg = errors.isNotEmpty ? errors.first.toString() : 'Validation failed.';
          } else {
            msg = 'Validation error occurred.';
          }
        }
        return ApiException(message: msg, statusCode: status, data: resData);
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return const ApiException(message: 'No internet connection. Please verify your network.');
      default:
        return ApiException(message: error.message ?? 'Something went wrong.');
    }
  }

  @override
  String toString() => message;
}
