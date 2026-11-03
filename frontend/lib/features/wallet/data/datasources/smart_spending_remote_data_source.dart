import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho màn "Mua Hay Chờ" — kết nối /simulations, /recommendations, /purchases
abstract class SmartSpendingRemoteDataSource {
  // Simulations
  /// Mô phỏng tác động mua hàng
  Future<Map<String, dynamic>> simulatePurchase({
    required String price,
    String? billOccurrenceId,
  });

  /// Mô phỏng lương về muộn
  Future<Map<String, dynamic>> simulateSalaryDelay({
    required int delayDays,
  });

  /// Quy đổi giá theo giờ công
  Future<Map<String, dynamic>> simulateWorkHours({
    required String price,
  });

  /// Thử giảm một thói quen chi tiêu
  Future<Map<String, dynamic>> simulateHabit({
    required String amountPerOccurrence,
    required int occurrencesPerWeek,
    required int weeks,
    required int reductionPercent,
  });

  // Recommendations
  /// Lấy đề xuất so sánh phương án mua hàng
  Future<Map<String, dynamic>> getRecommendations({
    required String question,
    required List<String> options,
    String? minimumDaily,
  });

  // Purchases
  /// Danh sách mong muốn
  Future<List<Map<String, dynamic>>> getPurchases();

  /// Lưu khoản mua để cân nhắc
  Future<Map<String, dynamic>> createPurchase({
    required String name,
    required String price,
    String? categoryId,
    String? remindAt,
  });

  /// Chi tiết khoản mua và tác động hiện tại
  Future<Map<String, dynamic>> getPurchase(String id);

  /// Sửa giá hoặc nhắc lại khoản mua
  Future<Map<String, dynamic>> updatePurchase({
    required String id,
    String? name,
    String? price,
    String? remindAt,
  });

  /// Xác nhận mua và tạo giao dịch thực tế
  Future<Map<String, dynamic>> buyPurchase({
    required String id,
    required String walletId,
    required String occurredAt,
    bool? trackReview,
  });

  /// Để dành mua sau: tạo mục tiêu, chưa phân bổ tiền
  Future<Map<String, dynamic>> createSavingPlan({
    required String purchaseId,
    required String targetAt,
    String? dailySaving,
  });

  /// Lấy thông tin tổng quan tài chính (dùng trong mua hay chờ)
  Future<Map<String, dynamic>> getDashboardOverview();
}

class SmartSpendingRemoteDataSourceImpl
    implements SmartSpendingRemoteDataSource {
  final ApiClient _apiClient;

  SmartSpendingRemoteDataSourceImpl(this._apiClient);

  // Simulations Implementation
  @override
  Future<Map<String, dynamic>> simulatePurchase({
    required String price,
    String? billOccurrenceId,
  }) async {
    final data = <String, dynamic>{'price': price};
    if (billOccurrenceId != null) data['billOccurrenceId'] = billOccurrenceId;

    final result = await _apiClient.post('/simulations/purchase', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> simulateSalaryDelay({
    required int delayDays,
  }) async {
    final result = await _apiClient.post('/simulations/salary-delay', data: {
      'delayDays': delayDays,
    });
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> simulateWorkHours({
    required String price,
  }) async {
    final result = await _apiClient.post('/simulations/work-hours', data: {
      'price': price,
    });
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> simulateHabit({
    required String amountPerOccurrence,
    required int occurrencesPerWeek,
    required int weeks,
    required int reductionPercent,
  }) async {
    final result = await _apiClient.post('/simulations/habit', data: {
      'amountPerOccurrence': amountPerOccurrence,
      'occurrencesPerWeek': occurrencesPerWeek,
      'weeks': weeks,
      'reductionPercent': reductionPercent,
    });
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  // Recommendations Implementation
  @override
  Future<Map<String, dynamic>> getRecommendations({
    required String question,
    required List<String> options,
    String? minimumDaily,
  }) async {
    final data = <String, dynamic>{
      'question': question,
      'options': options,
    };
    if (minimumDaily != null) data['minimumDaily'] = minimumDaily;

    final result = await _apiClient.post('/recommendations', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  // Purchases Implementation
  @override
  Future<List<Map<String, dynamic>>> getPurchases() async {
    final result = await _apiClient.get('/purchases');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        final data = res['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
        return [];
      },
    );
  }

  @override
  Future<Map<String, dynamic>> createPurchase({
    required String name,
    required String price,
    String? categoryId,
    String? remindAt,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'price': price,
    };
    if (categoryId != null) data['categoryId'] = categoryId;
    if (remindAt != null) data['remindAt'] = remindAt;

    final result = await _apiClient.post('/purchases', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getPurchase(String id) async {
    final result = await _apiClient.get('/purchases/$id');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updatePurchase({
    required String id,
    String? name,
    String? price,
    String? remindAt,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (remindAt != null) data['remindAt'] = remindAt;

    final result = await _apiClient.patch('/purchases/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> buyPurchase({
    required String id,
    required String walletId,
    required String occurredAt,
    bool? trackReview,
  }) async {
    final data = <String, dynamic>{
      'walletId': walletId,
      'occurredAt': occurredAt,
    };
    if (trackReview != null) data['trackReview'] = trackReview;

    final result = await _apiClient.post('/purchases/$id/buy', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> createSavingPlan({
    required String purchaseId,
    required String targetAt,
    String? dailySaving,
  }) async {
    final data = <String, dynamic>{
      'targetAt': targetAt,
    };
    if (dailySaving != null) data['dailySaving'] = dailySaving;

    final result =
        await _apiClient.post('/purchases/$purchaseId/saving-plan', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getDashboardOverview() async {
    final result = await _apiClient.get('/dashboard');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }
}

final smartSpendingRemoteDataSourceProvider =
    Provider<SmartSpendingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SmartSpendingRemoteDataSourceImpl(apiClient);
});
