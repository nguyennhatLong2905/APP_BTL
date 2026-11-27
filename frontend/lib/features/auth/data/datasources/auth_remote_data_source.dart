import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/core/providers/network_providers.dart';

abstract class AuthRemoteDataSource {
  /// Login — trả về {accessToken, user}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  /// Demo login (backend: POST /auth/demo, chỉ bật trên localhost dev)
  Future<Map<String, dynamic>> demoLogin();

  /// Register — trả về {accessToken, user}
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> requestRegisterOtp({
    required String name,
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otp,
  });

  /// Đổi mật khẩu — trả về {accessToken}
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Gửi mã OTP đặt lại mật khẩu qua email
  Future<Map<String, dynamic>> requestPasswordResetOtp({required String email});

  /// Xác minh mã OTP — trả về {verified, resetToken, expiresInSeconds}
  Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  });

  /// Đặt lại mật khẩu sau khi xác minh OTP
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        // Backend: { data: { accessToken: "...", user: {...} } }
        return body['data'] as Map<String, dynamic>;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> demoLogin() async {
    final result = await _apiClient.post('/auth/demo', data: {});
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/auth/register',
      data: {'displayName': name, 'email': email, 'password': password},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> requestRegisterOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/auth/register/request-otp',
      data: {'displayName': name, 'email': email, 'password': password},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) => (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _apiClient.post(
      '/auth/register/verify-otp',
      data: {'email': email, 'otp': otp},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) => (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _apiClient.post(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> requestPasswordResetOtp({
    required String email,
  }) async {
    final result = await _apiClient.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _apiClient.post(
      '/auth/verify-reset-otp',
      data: {'email': email, 'otp': otp},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>;
      },
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final result = await _apiClient.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
    );
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }
}

// Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

// ApiClient provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
