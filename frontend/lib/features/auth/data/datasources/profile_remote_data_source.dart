import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho quản lý Profile — kết nối /api/v1/me
abstract class ProfileRemoteDataSource {
  /// Lấy hồ sơ và thiết lập người dùng
  Future<Map<String, dynamic>> getProfile();

  /// Cập nhật ngày lương, ẩn số tiền và thiết lập
  Future<Map<String, dynamic>> updateProfile({
    String? nextPayday,
    Map<String, dynamic>? settings,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getProfile() async {
    final result = await _apiClient.get('/me');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? nextPayday,
    Map<String, dynamic>? settings,
  }) async {
    final data = <String, dynamic>{};
    if (nextPayday != null) {
      data['nextPayday'] = nextPayday;
    }
    if (settings != null) {
      data['settings'] = settings;
    }

    final result = await _apiClient.patch('/me', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }
}

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRemoteDataSourceImpl(apiClient);
});
