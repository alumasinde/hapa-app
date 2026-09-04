import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAccessToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> getHealth() => get('/health');
  Future<Map<String, dynamic>> getCategories() => get('/categories');
  Future<Map<String, dynamic>> getModes() => get('/modes');

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get(path);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(path, data: body);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Unexpected API response');
  }
}
