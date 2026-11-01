import 'package:dio/dio.dart';
import '../../constants/app_constants.dart';
import '../../storage/secure_storage_service.dart';

/// Interceptor tự động đính kèm Token JWT vào mọi Request Header
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}
