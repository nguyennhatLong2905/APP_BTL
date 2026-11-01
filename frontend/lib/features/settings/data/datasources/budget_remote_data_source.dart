import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho Budget/Plans — kết nối /api/v1/screens/plans & /budgets
abstract class BudgetRemoteDataSource {
  Future<Map<String, dynamic>> getPlansScreen();
  Future<List<Map<String, dynamic>>> getBudgets();
  Future<List<Map<String, dynamic>>> getGoals();
  Future<List<Map<String, dynamic>>> getUpcomingBills();
  Future<Map<String, dynamic>> createBudget({
    required String categoryId,
    required int limitAmount,
    required String period, // 'monthly'
  });
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final ApiClient _apiClient;

  BudgetRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getPlansScreen() async {
    final result = await _apiClient.get('/screens/plans');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getBudgets() async {
    final result = await _apiClient.get('/budgets');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        final d = body['data'];
        if (d is List) return d.cast<Map<String, dynamic>>();
        if (d is Map && d['items'] is List) {
          return (d['items'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getGoals() async {
    final result = await _apiClient.get('/goals');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        final d = body['data'];
        if (d is List) return d.cast<Map<String, dynamic>>();
        return [];
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getUpcomingBills() async {
    final result = await _apiClient.get('/bills', queryParameters: {'status': 'pending', 'limit': '10'});
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        final d = body['data'];
        if (d is List) return d.cast<Map<String, dynamic>>();
        if (d is Map && d['items'] is List) {
          return (d['items'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      },
    );
  }

  @override
  Future<Map<String, dynamic>> createBudget({
    required String categoryId,
    required int limitAmount,
    required String period,
  }) async {
    final result = await _apiClient.post('/budgets', data: {
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'period': period,
    });
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }
}

final budgetRemoteDataSourceProvider =
    Provider<BudgetRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BudgetRemoteDataSourceImpl(apiClient);
});
