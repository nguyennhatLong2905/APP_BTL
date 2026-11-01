import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho giao dịch — kết nối /api/v1/transactions
abstract class TransactionRemoteDataSource {
  /// Lấy danh sách giao dịch (có phân trang cursor)
  Future<Map<String, dynamic>> getTransactions({
    String? cursor,
    int limit = 20,
    String? walletId,
    String? categoryId,
  });

  /// Tạo giao dịch mới
  Future<Map<String, dynamic>> createTransaction({
    required String type, // 'income' | 'expense' | 'transfer'
    required int amount,  // VND (integer)
    required String occurredAt, // ISO8601
    String? categoryId,
    String? walletId,
    String? toWalletId,
    String? memo,
    String? note,
  });

  /// Sửa giao dịch
  Future<Map<String, dynamic>> updateTransaction({
    required String id,
    required Map<String, dynamic> data,
  });

  /// Hủy giao dịch (void)
  Future<void> voidTransaction(String id);

  /// Lấy danh sách ví
  Future<List<Map<String, dynamic>>> getWallets();

  /// Lấy danh sách danh mục
  Future<List<Map<String, dynamic>>> getCategories();
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient _apiClient;

  TransactionRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getTransactions({
    String? cursor,
    int limit = 20,
    String? walletId,
    String? categoryId,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (walletId != null) params['walletId'] = walletId;
    if (categoryId != null) params['categoryId'] = categoryId;

    final result = await _apiClient.get('/transactions', queryParameters: params);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> createTransaction({
    required String type,
    required int amount,
    required String occurredAt,
    String? categoryId,
    String? walletId,
    String? toWalletId,
    String? memo,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'type': type,
      'amount': amount,
      'occurredAt': occurredAt,
    };
    if (categoryId != null) data['categoryId'] = categoryId;
    if (walletId != null) data['walletId'] = walletId;
    if (toWalletId != null) data['toWalletId'] = toWalletId;
    if (memo != null && memo.isNotEmpty) data['memo'] = memo;
    if (note != null && note.isNotEmpty) data['note'] = note;

    final result = await _apiClient.post('/transactions', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateTransaction({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final result = await _apiClient.put('/transactions/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<void> voidTransaction(String id) async {
    final result = await _apiClient.post('/transactions/$id/void');
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getWallets() async {
    final result = await _apiClient.get('/wallets');
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
        return [];
      },
    );
  }
}

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionRemoteDataSourceImpl(apiClient);
});
