import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/core/providers/network_providers.dart';

/// Datasource cho quản lý Attachments — kết nối /api/v1/attachments
abstract class AttachmentRemoteDataSource {
  /// Upload ảnh hóa đơn PNG/JPEG/WebP tối đa 2 MB
  Future<String> uploadAttachment(XFile file);

  /// Download ảnh hóa đơn có xác thực
  Future<List<int>> downloadAttachment(String id);
}

class AttachmentRemoteDataSourceImpl implements AttachmentRemoteDataSource {
  final Dio _dio;
  final ApiClient _apiClient;

  AttachmentRemoteDataSourceImpl(this._dio, this._apiClient);

  @override
  Future<String> uploadAttachment(XFile file) async {
    final extension = file.name.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => throw ServerException(
        message: 'Chỉ hỗ trợ ảnh PNG, JPEG hoặc WebP.',
      ),
    };
    final size = await file.length();
    if (size == 0 || size > 2000000) {
      throw ServerException(
        message: 'Ảnh phải có dung lượng từ 1 byte đến 2 MB.',
      );
    }
    final result = await _apiClient.post(
      '/attachments',
      data: {
        'filename': file.name,
        'mimeType': mimeType,
        'base64': base64Encode(await file.readAsBytes()),
      },
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final response = body as Map<String, dynamic>;
        final data = response['data'] as Map<String, dynamic>? ?? response;
        final id = data['_id']?.toString();
        if (id == null || id.isEmpty) {
          throw ServerException(message: 'Không nhận được mã ảnh hóa đơn.');
        }
        return id;
      },
    );
  }

  @override
  Future<List<int>> downloadAttachment(String id) async {
    try {
      final response = await _dio.get(
        '/attachments/$id',
        options: Options(responseType: ResponseType.bytes),
      );

      return response.data as List<int>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerException(message: 'Attachment không tồn tại');
      }
      throw ServerException(
        message: e.message ?? 'Lỗi khi download attachment',
      );
    } catch (e) {
      throw ServerException(message: 'Lỗi khi download attachment: $e');
    }
  }
}

final attachmentRemoteDataSourceProvider = Provider<AttachmentRemoteDataSource>(
  (ref) {
    final dio = ref.watch(dioProvider);
    return AttachmentRemoteDataSourceImpl(dio, ref.watch(apiClientProvider));
  },
);
