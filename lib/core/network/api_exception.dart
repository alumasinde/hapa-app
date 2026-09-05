import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, String> fieldErrors;

  factory ApiException.fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return const ApiException(
        message: 'Unable to connect to the Hapa API. Check that the API server is running and reachable from this phone.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Unable to reach the Hapa API. Check your Wi-Fi connection and API server address.',
      );
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        message: 'The Hapa API took too long to respond. Please try again.',
      );
    }

    final data = error.response?.data;
    if (data is Map) {
      final errorBody = data['error'];
      if (errorBody is Map) {
        return ApiException(
          message: errorBody['message']?.toString() ?? 'Request failed',
          statusCode: error.response?.statusCode,
          code: errorBody['code']?.toString(),
          fieldErrors: _fieldErrors(errorBody['details']),
        );
      }
    }

    return ApiException(
      message: error.message ?? 'Unable to reach the Hapa API',
      statusCode: error.response?.statusCode,
    );
  }

  static Map<String, String> _fieldErrors(dynamic details) {
    if (details is! Map) return const {};
    return details.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  @override
  String toString() => message;
}
