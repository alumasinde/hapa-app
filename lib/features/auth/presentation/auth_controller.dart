import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/auth_secure_storage.dart';
import '../domain/user.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.error});

  final AuthStatus status;
  final User? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final authStorageProvider = Provider<AuthSecureStorage>(
  (ref) => AuthSecureStorage(),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(authStorageProvider),
    ref.watch(apiClientProvider),
  )..restoreSession();
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._storage, this._api)
      : super(const AuthState(status: AuthStatus.checking));

  final AuthRepository _repository;
  final AuthSecureStorage _storage;
  final ApiClient _api;

  Future<void> restoreSession() async {
    final tokens = await _storage.read();
    if (tokens == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    _api.setAccessToken(tokens.token);
    try {
      final user = await _repository.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await logout();
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final session = await _repository.login(
        email: email,
        password: password,
      );
      await _storage.save(session.tokens);
      _api.setAccessToken(session.tokens.token);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _message(error),
      );
      rethrow;
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final session = await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
      await _storage.save(session.tokens);
      _api.setAccessToken(session.tokens.token);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _message(error),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (_storage != null) {
        await _storage.clear();
      }
    } finally {
      _api.clearAccessToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  String _message(Object error) {
    final message = error.toString();
    if (message.startsWith('ApiException: ')) {
      return message.substring('ApiException: '.length);
    }
    return 'Something went wrong. Please try again.';
  }
}
