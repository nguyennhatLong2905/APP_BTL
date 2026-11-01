import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho màn "Nhìn Lại Nhật Ký" — kết nối /reflections & /screens/review
abstract class TimelineRemoteDataSource {
  Future<Map<String, dynamic>> getReviewScreen();
  Future<List<Map<String, dynamic>>> getReflections({int limit = 20});
  Future<Map<String, dynamic>> createReflection({
    required String periodStart,
    required String periodEnd,
    String? text,
    int? moodScore,
  });
  Future<List<Map<String, dynamic>>> getNotifications();
  Future<void> markNotificationRead(String id);
}

class TimelineRemoteDataSourceImpl implements TimelineRemoteDataSource {
  final ApiClient _apiClient;

  TimelineRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getReviewScreen() async {
    final result = await _apiClient.get('/screens/review');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getReflections({int limit = 20}) async {
    final result = await _apiClient.get('/reflections', queryParameters: {'limit': limit});
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
  Future<Map<String, dynamic>> createReflection({
    required String periodStart,
    required String periodEnd,
    String? text,
    int? moodScore,
  }) async {
    final data = <String, dynamic>{
      'periodStart': periodStart,
      'periodEnd': periodEnd,
    };
    if (text != null) data['text'] = text;
    if (moodScore != null) data['moodScore'] = moodScore;

    final result = await _apiClient.post('/reflections', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

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
