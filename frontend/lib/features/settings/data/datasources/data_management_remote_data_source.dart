import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';

abstract class DataManagementRemoteDataSource {
  Future<String> exportTransactionsCsv();
  Future<Map<String, dynamic>> createBackup();
  Future<Map<String, dynamic>> previewErase();
  Future<Map<String, dynamic>> eraseData({
    required String previewId,
    required String confirmation,
  });
}

class DataManagementRemoteDataSourceImpl
    implements DataManagementRemoteDataSource {
  final ApiClient _apiClient;

  DataManagementRemoteDataSourceImpl(this._apiClient);

  @override
  Future<String> exportTransactionsCsv() async {
    final result = await _apiClient.get('/exports/transactions.csv');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        if (data is String) return data;
        return data.toString();
      },
    );
  }

  @override
  Future<Map<String, dynamic>> createBackup() async {
    final result = await _apiClient.get('/backup');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> previewErase() async {
    final result = await _apiClient.post('/data/erase-preview', data: {});
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> eraseData({
    required String previewId,
    required String confirmation,
  }) async {
    final result = await _apiClient.post(
      '/data/$previewId/erase',
      data: {'confirmation': confirmation},
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }
}

final dataManagementRemoteDataSourceProvider =
    Provider<DataManagementRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DataManagementRemoteDataSourceImpl(apiClient);
});
