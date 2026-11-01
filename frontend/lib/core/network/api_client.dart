import 'package:fpdart/fpdart.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/failures.dart';

/// ApiClient dùng Dio với tự động gắn Idempotency-Key cho mọi write request
class ApiClient {
  final Dio _dio;
  final _uuid = const Uuid();

  ApiClient(this._dio);

  // GET request
  Future<Either<Failure, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return Right(response.data);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  // POST request — tự động gắn Idempotency-Key
  Future<Either<Failure, dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(
          headers: {'Idempotency-Key': _uuid.v4()},
        ),
      );
      return Right(response.data);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  // PUT request — tự động gắn Idempotency-Key
  Future<Either<Failure, dynamic>> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: Options(
          headers: {'Idempotency-Key': _uuid.v4()},
        ),
      );
      return Right(response.data);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  // PATCH request — tự động gắn Idempotency-Key
  Future<Either<Failure, dynamic>> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        options: Options(
          headers: {'Idempotency-Key': _uuid.v4()},
        ),
      );
      return Right(response.data);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  // DELETE request
  Future<Either<Failure, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return Right(response.data);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  // Handle Dio errors
  Failure _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerFailure(message: 'Connection timeout');
      case DioExceptionType.badResponse:
        final msg = _extractMessage(e);
        switch (e.response?.statusCode) {
          case 400:
            return ServerFailure(message: msg);
          case 401:
            return UnauthorizedFailure(message: msg);
          case 403:
            return ServerFailure(message: msg);
          case 404:
            return ServerFailure(message: msg);
          case 409:
            return ServerFailure(message: msg); // Duplicate / conflict
          case 500:
          case 501:
          case 502:
          case 503:
            return ServerFailure(message: msg);
          default:
            return ServerFailure(message: msg);
        }
      case DioExceptionType.cancel:
        return const ServerFailure(message: 'Request cancelled');
      case DioExceptionType.unknown:
        if (e.error.toString().contains('SocketException')) {
          return const ServerFailure(message: 'No internet connection');
        }
        return const ServerFailure(message: 'Unknown error occurred');
      default:
        return const ServerFailure(message: 'Unknown error occurred');
    }
  }

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        return data['message']?.toString() ??
            data['error']?.toString() ??
            'Unknown error occurred';
      }
    } catch (_) {}
    return 'Unknown error occurred';
  }

  // Add token to headers
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Remove token from headers
  void removeToken() {
    _dio.options.headers.remove('Authorization');
  }
}
