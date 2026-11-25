import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/providers/network_providers.dart';

/// Datasource cho Data Management — kết nối /api/v1/imports, /exports, /backup, /data
abstract class DataManagementRemoteDataSource {
  // Import CSV
  Future<Map<String, dynamic>> previewImport(String csv);
  Future<Map<String, dynamic>> commitImport({
    required String previewId,
    required List<int> selectedRows,
    bool includeSuspectedDuplicates = false,
  });

  // Export CSV
  Future<List<int>> exportTransactionsCsv({
    String? startAt,
    String? endAt,
    String? walletId,
  });

  // Backup
  Future<Map<String, dynamic>> createBackup();
  Future<Map<String, dynamic>> previewRestore(Map<String, dynamic> backupData);
  Future<Map<String, dynamic>> restoreBackup({
    required String previewId,
    required String confirmation,
  });

  // Data Erase
  Future<Map<String, dynamic>> previewErase();
  Future<void> eraseData({
    required String previewId,
    required String confirmation,
  });
}

class DataManagementRemoteDataSourceImpl
    implements DataManagementRemoteDataSource {
  final Dio _dio;
  final ApiClient _api;

  DataManagementRemoteDataSourceImpl(this._dio) : _api = ApiClient(_dio);

  @override
  Future<Map<String, dynamic>> previewImport(String csv) =>
      _post('/imports/preview', {
        'csv': csv,
        'mapping': {
          for (final field in [
            'type',
            'amount',
            'occurredAt',
            'walletId',
            'fromWalletId',
            'toWalletId',
            'categoryId',
            'note',
          ])
            field: field,
        },
      });

  @override
  Future<Map<String, dynamic>> commitImport({
    required String previewId,
    required List<int> selectedRows,
    bool includeSuspectedDuplicates = false,
  }) => _post('/imports/$previewId/commit', {
    'selectedRows': selectedRows,
    'includeSuspectedDuplicates': includeSuspectedDuplicates,
  });

  // Export Implementation
  @override
  Future<List<int>> exportTransactionsCsv({
    String? startAt,
    String? endAt,
    String? walletId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startAt != null) params['startAt'] = startAt;
      if (endAt != null) params['endAt'] = endAt;
      if (walletId != null) params['walletId'] = walletId;

      final response = await _dio.get(
        '/exports/transactions.csv',
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );

      return response.data as List<int>;
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi export CSV');
    }
  }

  @override
  Future<Map<String, dynamic>> createBackup() async {
    final result = await _api.get('/backup');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      _data,
    );
  }

  @override
  Future<Map<String, dynamic>> previewRestore(
    Map<String, dynamic> backupData,
  ) => _post('/backup/preview', backupData);

  @override
  Future<Map<String, dynamic>> restoreBackup({
    required String previewId,
    required String confirmation,
  }) => _post('/backup/$previewId/restore', {'confirmation': confirmation});

  @override
  Future<Map<String, dynamic>> previewErase() =>
      _post('/data/erase-preview', {});

  @override
  Future<void> eraseData({
    required String previewId,
    required String confirmation,
  }) async {
    await _post('/data/$previewId/erase', {'confirmation': confirmation});
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.post(path, data: body);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      _data,
    );
  }

  Map<String, dynamic> _data(dynamic response) =>
      (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
}

final dataManagementRemoteDataSourceProvider =
    Provider<DataManagementRemoteDataSource>((ref) {
      return DataManagementRemoteDataSourceImpl(ref.watch(dioProvider));
    });
