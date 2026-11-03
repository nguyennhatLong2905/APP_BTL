import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/core/providers/network_providers.dart';

/// Datasource cho quản lý Attachments — kết nối /api/v1/attachments
abstract class AttachmentRemoteDataSource {
  /// Upload ảnh hóa đơn PNG/JPEG/WebP tối đa 2 MB
  Future<Map<String, dynamic>> uploadAttachment(File file);

  /// Download ảnh hóa đơn có xác thực
  Future<List<int>> downloadAttachment(String id);
}

class AttachmentRemoteDataSourceImpl implements AttachmentRemoteDataSource {
  final Dio _dio;

  AttachmentRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> uploadAttachment(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/attachments',
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
      if (e.response?.statusCode == 413) {
        throw ServerException(message: 'File quá lớn (tối đa 2MB)');
      }
      throw ServerException(
          message: e.message ?? 'Lỗi khi upload attachment');
    } catch (e) {
      throw ServerException(message: 'Lỗi khi upload attachment: $e');
    }
  }

  @override
  Future<List<int>> downloadAttachment(String id) async {
    try {
      final response = await _dio.get(
        '/attachments/$id',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      return response.data as List<int>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerException(message: 'Attachment không tồn tại');
      }
      throw ServerException(
          message: e.message ?? 'Lỗi khi download attachment');
    } catch (e) {
      throw ServerException(message: 'Lỗi khi download attachment: $e');
    }
  }
}

final attachmentRemoteDataSourceProvider =
    Provider<AttachmentRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AttachmentRemoteDataSourceImpl(dio);
});
