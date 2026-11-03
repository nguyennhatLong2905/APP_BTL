import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/core/providers/network_providers.dart';

/// Datasource cho Data Management — kết nối /api/v1/imports, /exports, /backup, /data
abstract class DataManagementRemoteDataSource {
  // Import CSV
  Future<Map<String, dynamic>> previewImport(File file);
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

  DataManagementRemoteDataSourceImpl(this._dio);

  // Import Implementation
  @override
  Future<Map<String, dynamic>> previewImport(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/imports/preview',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      final body = response.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? body;
    } on DioException catch (e) {
      throw ServerException(
          message: e.message ?? 'Lỗi khi preview import CSV');
    }
  }

  @override
  Future<Map<String, dynamic>> commitImport({
    required String previewId,
    required List<int> selectedRows,
    bool includeSuspectedDuplicates = false,
  }) async {
    try {
      final response = await _dio.post('/imports/$previewId/commit', data: {
        'selectedRows': selectedRows,
        'includeSuspectedDuplicates': includeSuspectedDuplicates,
      });

      final body = response.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? body;
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi commit import CSV');
    }
  }

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
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      return response.data as List<int>;
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi export CSV');
    }
  }

  // Backup Implementation
  @override
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final response = await _dio.get('/backup');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi tạo backup');
    }
  }

  @override
  Future<Map<String, dynamic>> previewRestore(
      Map<String, dynamic> backupData) async {
    try {
      final response = await _dio.post('/backup/preview', data: backupData);
      final body = response.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? body;
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi preview restore');
    }
  }

  @override
  Future<Map<String, dynamic>> restoreBackup({
    required String previewId,
    required String confirmation,
  }) async {
    try {
      final response = await _dio.post('/backup/$previewId/restore', data: {
        'confirmation': confirmation,
      });
      final body = response.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? body;
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi restore backup');
    }
  }

  // Data Erase Implementation
  @override
  Future<Map<String, dynamic>> previewErase() async {
    try {
      final response = await _dio.post('/data/erase-preview');
      final body = response.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? body;
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi preview erase');
    }
  }

  @override
  Future<void> eraseData({
    required String previewId,
    required String confirmation,
  }) async {
    try {
      await _dio.post('/data/$previewId/erase', data: {
        'confirmation': confirmation,
      });
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Lỗi khi erase data');
    }
  }
}

final dataManagementRemoteDataSourceProvider =
    Provider<DataManagementRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DataManagementRemoteDataSourceImpl(dio);
});
