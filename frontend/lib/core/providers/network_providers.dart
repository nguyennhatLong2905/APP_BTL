import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/env_config.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../network/interceptors/retry_interceptor.dart';
import '../storage/secure_storage_service.dart';

part 'network_providers.g.dart';

@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService.create();
}

@riverpod
Dio dio(Ref ref) {
  final dio = Dio();
  final secureStorage = ref.watch(secureStorageServiceProvider);

  dio.options.baseUrl = EnvConfig.baseUrl;
  dio.options.connectTimeout = const Duration(milliseconds: 30000);
  dio.options.receiveTimeout = const Duration(milliseconds: 30000);
  dio.options.headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 1. AuthInterceptor - Tự động đính kèm Bearer Token
  dio.interceptors.add(AuthInterceptor(secureStorage));

  // 2. ErrorInterceptor - Bắt và chuẩn hóa lỗi NestJS
  dio.interceptors.add(ErrorInterceptor());

  // 3. LogInterceptor - Debug API requests/responses
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ),
  );

  // 4. RetryInterceptor - Tự động thử lại khi mất mạng chập chờn
  dio.interceptors.add(RetryInterceptor(dio: dio));

  return dio;
}
