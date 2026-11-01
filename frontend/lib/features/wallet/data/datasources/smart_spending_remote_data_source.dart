import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho màn "Mua Hay Chờ" — kết nối /simulations/purchase & /recommendations
abstract class SmartSpendingRemoteDataSource {
  /// Mô phỏng tác động mua hàng
  Future<Map<String, dynamic>> simulatePurchase({
    required int amount,
    required String itemName,
    String? categoryId,
  });

  /// Lấy đề xuất so sánh phương án mua hàng
  Future<Map<String, dynamic>> getRecommendations({
    required int budget,
    required String itemName,
  });

  /// Lấy thông tin tổng quan tài chính (dùng trong mua hay chờ)
  Future<Map<String, dynamic>> getDashboardOverview();
}

class SmartSpendingRemoteDataSourceImpl
    implements SmartSpendingRemoteDataSource {
  final ApiClient _apiClient;

  SmartSpendingRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> simulatePurchase({
    required int amount,
    required String itemName,
    String? categoryId,
  }) async {
    final data = <String, dynamic>{
      'amount': amount,
      'itemName': itemName,
    };
    if (categoryId != null) data['categoryId'] = categoryId;

    final result = await _apiClient.post('/simulations/purchase', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getRecommendations({
    required int budget,
    required String itemName,
  }) async {
    final result = await _apiClient.post('/recommendations', data: {
      'budget': budget,
      'itemName': itemName,
    });
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getDashboardOverview() async {
    final result = await _apiClient.get('/dashboard');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }
}

final smartSpendingRemoteDataSourceProvider =
    Provider<SmartSpendingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SmartSpendingRemoteDataSourceImpl(apiClient);
});
