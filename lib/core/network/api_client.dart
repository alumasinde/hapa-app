import 'package:dio/dio.dart';
import '../config/api_config.dart';

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

  Future<Map<String, dynamic>> getHealth() async {
    final response = await _dio.get('/health');
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getCategories() async {
    final response = await _dio.get('/categories');
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getModes() async {
    final response = await _dio.get('/modes');
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Unexpected API response');
  }
}
