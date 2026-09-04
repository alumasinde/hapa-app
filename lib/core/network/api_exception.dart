import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errorBody = data['error'];
      if (errorBody is Map) {
        return ApiException(
          message: errorBody['message']?.toString() ?? 'Request failed',
          statusCode: error.response?.statusCode,
          code: errorBody['code']?.toString(),
        );
      }
    }

    return ApiException(
      message: error.message ?? 'Unable to reach the Hapa API',
      statusCode: error.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
