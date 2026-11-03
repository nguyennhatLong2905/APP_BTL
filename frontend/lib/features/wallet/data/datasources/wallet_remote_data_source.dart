import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho quản lý Ví — kết nối /api/v1/wallets
abstract class WalletRemoteDataSource {
  /// Lấy danh sách ví
  Future<List<Map<String, dynamic>>> getWallets();

  /// Tạo ví mới với số dư ban đầu
  Future<Map<String, dynamic>> createWallet({
    required String name,
    required String type, // 'cash' | 'bank' | 'ewallet' | 'savings'
    required String openingBalance,
    String? openingAt,
    String? currency,
  });

  /// Đổi tên hoặc lưu trữ ví
  Future<Map<String, dynamic>> updateWallet({
    required String id,
    String? name,
    String? status, // 'active' | 'archived'
    required int expectedVersion,
  });

  /// Đối chiếu và tạo điều chỉnh số dư
  Future<Map<String, dynamic>> reconcileWallet({
    required String id,
    required String actualBalance,
    required int expectedVersion,
    String? note,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient _apiClient;

  WalletRemoteDataSourceImpl(this._apiClient);

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
  Future<Map<String, dynamic>> createWallet({
    required String name,
    required String type,
    required String openingBalance,
    String? openingAt,
    String? currency,
  }) async {
    // Backend schema chỉ chấp nhận: name, type, openingBalance, openingAt
    // Không được gửi currency vì additionalProperties: false
    final data = <String, dynamic>{
      'name': name,
      'type': type,
      'openingBalance': openingBalance,
    };
    if (openingAt != null) {
      data['openingAt'] = openingAt;
    }

    final result = await _apiClient.post('/wallets', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateWallet({
    required String id,
    String? name,
    String? status,
    required int expectedVersion,
  }) async {
    final data = <String, dynamic>{
      'expectedVersion': expectedVersion,
    };
    if (name != null) data['name'] = name;
    if (status != null) data['status'] = status;

    final result = await _apiClient.patch('/wallets/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> reconcileWallet({
    required String id,
    required String actualBalance,
    required int expectedVersion,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'actualBalance': actualBalance,
      'expectedVersion': expectedVersion,
    };
    if (note != null && note.isNotEmpty) {
      data['note'] = note;
    }

    final result = await _apiClient.post('/wallets/$id/reconcile', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }
}

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRemoteDataSourceImpl(apiClient);
});
