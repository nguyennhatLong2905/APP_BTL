import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho quản lý Danh mục — kết nối /api/v1/categories
abstract class CategoryRemoteDataSource {
  /// Lấy danh sách danh mục thu chi
  Future<List<Map<String, dynamic>>> getCategories();

  /// Tạo danh mục mới
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String kind, // 'income' | 'expense'
    String? icon,
    String? color,
  });

  /// Sửa/lưu trữ danh mục
  Future<Map<String, dynamic>> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    String? status, // 'active' | 'archived'
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient _apiClient;

  CategoryRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    final result = await _apiClient.get('/categories');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        final data = res['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        if (data is Map && data['items'] is List) {
          return (data['items'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      },
    );
  }

  @override
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String kind,
    String? icon,
    String? color,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'kind': kind,
    };
    if (icon != null) data['icon'] = icon;
    if (color != null) data['color'] = color;

    final result = await _apiClient.post('/categories', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (icon != null) data['icon'] = icon;
    if (color != null) data['color'] = color;
    if (status != null) data['status'] = status;

    final result = await _apiClient.patch('/categories/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }
}

final categoryRemoteDataSourceProvider =
    Provider<CategoryRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoryRemoteDataSourceImpl(apiClient);
});
