import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho màn "Nhìn Lại Nhật Ký" — kết nối /reflections, /screens/review, /insights, /challenges
abstract class TimelineRemoteDataSource {
  // Review Screen
  Future<Map<String, dynamic>> getReviewScreen({String? startAt, String? endAt});
  Future<List<Map<String, dynamic>>> getReviewWeeks({int limit = 12});

  // Reflections
  /// Nhật ký Đáng tiền. Backend tự tạo bản ghi cho mọi giao dịch chi nên
  /// không còn endpoint "thêm vào nhật ký" — chỉ đọc và đánh giá.
  Future<List<Map<String, dynamic>>> getJournal({
    String status = 'all',
    int limit = 200,
  });
  Future<Map<String, dynamic>> rateReflection({
    required String id,
    required String rating, // 'worth_it' | 'neutral' | 'reconsider'
    String? note,
  });
  Future<void> skipReflection(String id);
  Future<List<Map<String, dynamic>>> getReflectionHistory({
    String status = 'rated',
    int limit = 50,
  });
  Future<List<Map<String, dynamic>>> getEvidence(List<String> transactionIds);

  /// Giao dịch chi của một danh mục trong khoảng thời gian (drill-down).
  Future<List<Map<String, dynamic>>> getCategoryTransactions({
    required String categoryId,
    required DateTime startAt,
    required DateTime endAt,
  });

  /// Đọc kỳ ngân sách để cập nhật hạn mức (chỉ khi người dùng xác nhận).
  Future<Map<String, dynamic>> getBudgetPlan(String budgetId);
  Future<void> updateBudgetPlan(String budgetId, Map<String, dynamic> data);

  // Insights
  Future<List<Map<String, dynamic>>> getInsights();
  Future<Map<String, dynamic>> generateInsights();
  Future<Map<String, dynamic>> applyInsight({
    required String id,
    String? budgetId,
    String? newLimit,
  });
  Future<void> dismissInsight(String id);

  // Challenges
  Future<List<Map<String, dynamic>>> getChallenges();
  Future<Map<String, dynamic>> createChallenge({
    required String categoryId,
    required String challengeType, // 'silence_48h' | 'habit_change'
    int? targetReduction,
  });
  Future<void> cancelChallenge(String id);

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications();
  Future<void> markNotificationRead(String id);
}

class TimelineRemoteDataSourceImpl implements TimelineRemoteDataSource {
  final ApiClient _apiClient;

  TimelineRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getReviewScreen({
    String? startAt,
    String? endAt,
  }) async {
    final params = <String, dynamic>{};
    if (startAt != null) params['startAt'] = startAt;
    if (endAt != null) params['endAt'] = endAt;
    final result = await _apiClient.get(
      '/screens/review',
      queryParameters: params.isEmpty ? null : params,
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getReviewWeeks({int limit = 12}) async {
    final result = await _apiClient.get(
      '/screens/review/weeks',
      queryParameters: {'limit': limit},
    );
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

  // Reflections Implementation
  @override
  Future<List<Map<String, dynamic>>> getJournal({
    String status = 'all',
    int limit = 200,
  }) async {
    final result = await _apiClient.get(
      '/reflections',
      queryParameters: {'status': status, 'limit': limit},
    );
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
  Future<Map<String, dynamic>> rateReflection({
    required String id,
    required String rating,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'status': 'rated',
      'rating': rating,
    };
    if (note != null) data['note'] = note;

    final result = await _apiClient.put('/reflections/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<void> skipReflection(String id) async {
    final result = await _apiClient.put('/reflections/$id', data: {
      'status': 'skipped',
    });
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getReflectionHistory({
    String status = 'rated',
    int limit = 50,
  }) async {
    final result = await _apiClient.get(
      '/reflections/history',
      queryParameters: {'status': status, 'limit': limit},
    );
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
  Future<List<Map<String, dynamic>>> getEvidence(
    List<String> transactionIds,
  ) async {
    if (transactionIds.isEmpty) return const [];
    final result = await _apiClient.post('/insights/evidence', data: {
      'transactionIds': transactionIds,
    });
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
  Future<List<Map<String, dynamic>>> getCategoryTransactions({
    required String categoryId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final result = await _apiClient.get(
      '/screens/transactions',
      queryParameters: {
        'categoryId': categoryId,
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
        'limit': 100,
      },
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        final d = body['data'];
        if (d is Map && d['items'] is List) {
          return (d['items'] as List).cast<Map<String, dynamic>>();
        }
        if (d is List) return d.cast<Map<String, dynamic>>();
        return [];
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getBudgetPlan(String budgetId) async {
    final result = await _apiClient.get('/budgets');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        final rows = (body['data'] as List?) ?? const [];
        final match = rows
            .cast<Map<String, dynamic>>()
            .firstWhere((b) => b['_id']?.toString() == budgetId,
                orElse: () => <String, dynamic>{});
        if (match.isEmpty) {
          throw ServerException(message: 'Không tìm thấy kỳ ngân sách.');
        }
        return match;
      },
    );
  }

  @override
  Future<void> updateBudgetPlan(
    String budgetId,
    Map<String, dynamic> data,
  ) async {
    final result = await _apiClient.put('/budgets/$budgetId', data: data);
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  // Insights Implementation
  @override
  Future<List<Map<String, dynamic>>> getInsights() async {
    final result = await _apiClient.get('/insights');
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
  Future<Map<String, dynamic>> generateInsights() async {
    final result = await _apiClient.post('/insights/generate');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> applyInsight({
    required String id,
    String? budgetId,
    String? newLimit,
  }) async {
    final data = <String, dynamic>{};
    if (budgetId != null) data['budgetId'] = budgetId;
    if (newLimit != null) data['newLimit'] = newLimit;

    final result = await _apiClient.post('/insights/$id/apply', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<void> dismissInsight(String id) async {
    final result = await _apiClient.post('/insights/$id/dismiss');
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  // Challenges Implementation
  @override
  Future<List<Map<String, dynamic>>> getChallenges() async {
    final result = await _apiClient.get('/challenges');
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
  Future<Map<String, dynamic>> createChallenge({
    required String categoryId,
    required String challengeType,
    int? targetReduction,
  }) async {
    final data = <String, dynamic>{
      'categoryId': categoryId,
      'challengeType': challengeType,
    };
    if (targetReduction != null) data['targetReduction'] = targetReduction;

    final result = await _apiClient.post('/challenges', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<void> cancelChallenge(String id) async {
    final result = await _apiClient.post('/challenges/$id/cancel');
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  // Notifications Implementation
  @override
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final result = await _apiClient.get('/notifications');
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
  Future<void> markNotificationRead(String id) async {
    final result = await _apiClient.post('/notifications/$id/read');
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }
}

final timelineRemoteDataSourceProvider =
    Provider<TimelineRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TimelineRemoteDataSourceImpl(apiClient);
});
