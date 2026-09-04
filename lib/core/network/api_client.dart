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

  Future<Map<String, dynamic>> getHealth() => _getMap('/health');
  Future<Map<String, dynamic>> getCategories() => _getMap('/categories');
  Future<Map<String, dynamic>> getModes() => _getMap('/modes');

  Future<Map<String, dynamic>> _getMap(String path) async {
    try {
      final response = await _dio.get(path);
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
