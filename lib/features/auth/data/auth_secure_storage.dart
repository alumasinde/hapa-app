import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_tokens.dart';

class AuthSecureStorage {
  static const _tokenKey = 'hapa.access_token';
  static const _refreshTokenKey = 'hapa.refresh_token';
  static const _storage = FlutterSecureStorage();

  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _tokenKey, value: tokens.token);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
  }

  Future<AuthTokens?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (token == null || token.isEmpty || refreshToken == null || refreshToken.isEmpty) return null;
    return AuthTokens(token: token, refreshToken: refreshToken);
  }

  Future<void> clear() => _storage.deleteAll();
}
