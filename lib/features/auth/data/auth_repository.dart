import '../../../core/network/api_client.dart';
import '../domain/auth_tokens.dart';
import '../domain/user.dart';

class AuthSession {
  const AuthSession({required this.tokens, required this.user});
  final AuthTokens tokens;
  final User user;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthSession> login({required String login, required String password}) async {
    final data = await _api.post('/auth/login', {'login': login, 'password': password});
    return _sessionFrom(data);
  }

  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String displayName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _api.post('/auth/register', {
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'email': email.isEmpty ? null : email,
      'phone': phone.isEmpty ? null : phone,
      'password': password,
    });
    return _sessionFrom(data);
  }

  Future<User> me() async {
    final data = await _api.get('/me');
    final user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : data;
    return User.fromJson(user);
  }

  AuthSession _sessionFrom(Map<String, dynamic> data) {
    final tokenData = data['tokens'] is Map
        ? Map<String, dynamic>.from(data['tokens'] as Map)
        : data;
    final userData = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    return AuthSession(tokens: AuthTokens.fromJson(tokenData), user: User.fromJson(userData));
  }
}
