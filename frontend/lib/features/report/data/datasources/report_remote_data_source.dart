import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho báo cáo — kết nối /api/v1/reports & /screens/transactions
abstract class ReportRemoteDataSource {
  Future<Map<String, dynamic>> getReport({
    required String period, // 'month' | 'week' | 'year'
    required DateTime date,
  });

  Future<Map<String, dynamic>> getTransactionHistory({
    String? cursor,
    int limit = 30,
    String? startDate,
    String? endDate,
    String? categoryId,
  });
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final ApiClient _apiClient;

  ReportRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getReport({
    required String period,
    required DateTime date,
  }) async {
    final params = <String, dynamic>{
      'period': period,
      'year': date.year.toString(),
      'month': date.month.toString().padLeft(2, '0'),
    };

    final result = await _apiClient.get('/reports', queryParameters: params);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getTransactionHistory({
    String? cursor,
    int limit = 30,
    String? startDate,
    String? endDate,
    String? categoryId,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (categoryId != null) params['categoryId'] = categoryId;

    final result = await _apiClient.get('/screens/transactions', queryParameters: params);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }
}

final reportRemoteDataSourceProvider =
    Provider<ReportRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportRemoteDataSourceImpl(apiClient);
});
