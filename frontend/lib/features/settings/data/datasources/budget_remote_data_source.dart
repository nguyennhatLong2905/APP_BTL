import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';

/// Datasource cho Budget/Plans — kết nối /api/v1/screens/plans & /budgets & /goals & /bills
abstract class BudgetRemoteDataSource {
  // Screens
  Future<Map<String, dynamic>> getPlansScreen();

  // Categories
  Future<List<Map<String, dynamic>>> getCategories();
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String kind, // 'expense' | 'income'
  });

  // Budgets
  Future<List<Map<String, dynamic>>> getBudgets();
  Future<Map<String, dynamic>> createBudget({
    required String name,
    required String periodType, // 'month' | 'pay_cycle'
    required String startAt, // ISO8601 có timezone
    required String endAt, // ISO8601 có timezone
    required List<Map<String, dynamic>> limits, // [{ categoryId, limit }]
    int? warningPercent,
  });

  /// Backend PUT /budgets/:id thay toàn bộ kỳ ngân sách (schema strict),
  /// nên phải gửi đủ name/periodType/startAt/endAt/limits.
  Future<Map<String, dynamic>> updateBudget({
    required String id,
    required String name,
    required String periodType,
    required String startAt,
    required String endAt,
    required List<Map<String, dynamic>> limits,
    int? warningPercent,
  });
  Future<void> closeBudget(String id);

  /// Xóa hẳn một kỳ ngân sách (chỉ xóa kế hoạch, không đụng ví/giao dịch).
  Future<void> deleteBudget(String id);

  // Goals
  Future<List<Map<String, dynamic>>> getGoals();
  Future<Map<String, dynamic>> createGoal({
    required String name,
    required String targetAmount,
    required String targetAt,
    bool? protect,
  });
  Future<Map<String, dynamic>> updateGoal({
    required String id,
    String? name,
    String? targetAmount,
    String? targetAt,
    bool? protect,
  });
  Future<Map<String, dynamic>> setGoalAllocation({
    required String goalId,
    required String walletId,
    required String amount, // Tổng phân bổ mới, không phải số cộng thêm
  });
  Future<Map<String, dynamic>> createSeasonalGoal({
    required String name,
    required String targetAmount,
    required String targetAt,
  });

  /// POST /goals với payload tự do (dùng cho provider mới)
  Future<Map<String, dynamic>> createGoalRaw(Map<String, dynamic> data);

  /// PATCH /goals/:id với payload tự do
  Future<Map<String, dynamic>> updateGoalPatch(
    String id,
    Map<String, dynamic> data,
  );

  // Bills
  Future<List<Map<String, dynamic>>> getBills({String? status});
  Future<List<Map<String, dynamic>>> getBillTemplates();
  Future<Map<String, dynamic>> createBillTemplate({
    required String name,
    required String amount,
    required String categoryId,
    required String frequency, // 'monthly' | 'weekly'
    required int dayOfPeriod,
  });
  Future<Map<String, dynamic>> updateBillTemplate({
    required String id,
    bool? active,
    bool? cancelFutureUnpaid,
  });
  Future<Map<String, dynamic>> updateBill({
    required String id,
    String? amount,
    String? dueAt,
    String? status,
    required int expectedVersion,
  });
  Future<Map<String, dynamic>> payBill({
    required String id,
    required String walletId,
    required String occurredAt,
    String? amount,
  });
  Future<void> linkBillTransaction({
    required String billId,
    required String transactionId,
    required int expectedVersion,
  });

  // ── Hóa đơn định kỳ (feature) ──────────────────────────────────────

  /// GET /screens/bills — tổng quan 3 lớp + danh sách hóa đơn + summary.
  Future<Map<String, dynamic>> getBillsScreen();

  /// POST /bill-templates với payload đầy đủ (chu kỳ, ngày bắt đầu/kết thúc…).
  Future<Map<String, dynamic>> createRecurringBill(Map<String, dynamic> data);

  /// PUT /bill-templates/:id — cập nhật toàn bộ định nghĩa hóa đơn định kỳ.
  Future<Map<String, dynamic>> updateRecurringBill(
    String id,
    Map<String, dynamic> data,
  );

  /// POST /bill-templates/:id/stop — ngừng định kỳ.
  Future<void> stopRecurringBill(String id, {bool cancelFutureUnpaid = true});

  /// DELETE /bills/:id — xóa một kỳ hóa đơn chưa thanh toán.
  Future<void> deleteBill(String id);

  /// POST /bills/:id/pay-preview — xem tác động 3 lớp trước khi trả.
  Future<Map<String, dynamic>> previewBillPayment(
    String id, {
    String? amount,
  });

  /// POST /bills/:id/settle — thanh toán bằng giao dịch chi mới (idempotent).
  Future<Map<String, dynamic>> settleBill({
    required String id,
    required String walletId,
    required String occurredAt,
    String? amount,
    String? note,
    bool allowNegativeAvailable = false,
  });

  /// POST /bills/:id/link — liên kết giao dịch chi đã có.
  Future<Map<String, dynamic>> linkBill({
    required String billId,
    required String transactionId,
    required int expectedVersion,
  });

  /// GET /bills/:id/candidate-transactions — giao dịch chi có thể liên kết.
  Future<List<Map<String, dynamic>>> getBillCandidateTransactions(
    String billId, {
    String? search,
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

  // Budgets Implementation
  @override
  Future<Map<String, dynamic>> createBudget({
    required String name,
    required String periodType,
    required String startAt,
    required String endAt,
    required List<Map<String, dynamic>> limits,
    int? warningPercent,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'periodType': periodType,
      'startAt': startAt,
      'endAt': endAt,
      'limits': limits,
    };
    if (warningPercent != null) data['warningPercent'] = warningPercent;

    final result = await _apiClient.post('/budgets', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateBudget({
    required String id,
    required String name,
    required String periodType,
    required String startAt,
    required String endAt,
    required List<Map<String, dynamic>> limits,
    int? warningPercent,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'periodType': periodType,
      'startAt': startAt,
      'endAt': endAt,
      'limits': limits,
    };
    if (warningPercent != null) data['warningPercent'] = warningPercent;

    final result = await _apiClient.put('/budgets/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    final result = await _apiClient.get('/categories');
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
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String kind,
  }) async {
    final result = await _apiClient.post('/categories', data: {
      'name': name,
      'kind': kind,
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
  Future<void> closeBudget(String id) async {
    final result = await _apiClient.post('/budgets/$id/close');
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  @override
  Future<void> deleteBudget(String id) async {
    final result = await _apiClient.delete('/budgets/$id');
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  // Goals Implementation
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
  Future<Map<String, dynamic>> createGoal({
    required String name,
    required String targetAmount,
    required String targetAt,
    bool? protect,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'targetAmount': targetAmount,
      'targetAt': targetAt,
    };
    if (protect != null) data['protect'] = protect;

    final result = await _apiClient.post('/goals', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateGoal({
    required String id,
    String? name,
    String? targetAmount,
    String? targetAt,
    bool? protect,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (targetAmount != null) data['targetAmount'] = targetAmount;
    if (targetAt != null) data['targetAt'] = targetAt;
    if (protect != null) data['protect'] = protect;

    final result = await _apiClient.patch('/goals/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> setGoalAllocation({
    required String goalId,
    required String walletId,
    required String amount,
  }) async {
    final result = await _apiClient.put('/goals/$goalId/allocation', data: {
      'walletId': walletId,
      'amount': amount,
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
  Future<Map<String, dynamic>> createSeasonalGoal({
    required String name,
    required String targetAmount,
    required String targetAt,
  }) async {
    final result = await _apiClient.post('/seasonal-goals', data: {
      'name': name,
      'targetAmount': targetAmount,
      'targetAt': targetAt,
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
  Future<Map<String, dynamic>> createGoalRaw(Map<String, dynamic> data) async {
    final result = await _apiClient.post('/goals', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateGoalPatch(
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _apiClient.patch('/goals/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  // Bills Implementation
  @override
  Future<List<Map<String, dynamic>>> getBills({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final result = await _apiClient.get('/bills', queryParameters: params);
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
  Future<List<Map<String, dynamic>>> getBillTemplates() async {
    final result = await _apiClient.get('/bill-templates');
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
  Future<Map<String, dynamic>> createBillTemplate({
    required String name,
    required String amount,
    required String categoryId,
    required String frequency,
    required int dayOfPeriod,
  }) async {
    final result = await _apiClient.post('/bill-templates', data: {
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'frequency': frequency,
      'dayOfPeriod': dayOfPeriod,
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
  Future<Map<String, dynamic>> updateBillTemplate({
    required String id,
    bool? active,
    bool? cancelFutureUnpaid,
  }) async {
    final data = <String, dynamic>{};
    if (active != null) data['active'] = active;
    if (cancelFutureUnpaid != null) {
      data['cancelFutureUnpaid'] = cancelFutureUnpaid;
    }

    final result = await _apiClient.patch('/bill-templates/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateBill({
    required String id,
    String? amount,
    String? dueAt,
    String? status,
    required int expectedVersion,
  }) async {
    final data = <String, dynamic>{
      'expectedVersion': expectedVersion,
    };
    if (amount != null) data['amount'] = amount;
    if (dueAt != null) data['dueAt'] = dueAt;
    if (status != null) data['status'] = status;

    final result = await _apiClient.patch('/bills/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> payBill({
    required String id,
    required String walletId,
    required String occurredAt,
    String? amount,
  }) async {
    final data = <String, dynamic>{
      'walletId': walletId,
      'occurredAt': occurredAt,
    };
    if (amount != null) data['amount'] = amount;

    final result = await _apiClient.post('/bills/$id/pay', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<void> linkBillTransaction({
    required String billId,
    required String transactionId,
    required int expectedVersion,
  }) async {
    final result = await _apiClient.post('/bills/$billId/link-transaction',
        data: {
          'transactionId': transactionId,
          'expectedVersion': expectedVersion,
        });
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  // ── Hóa đơn định kỳ ─────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getBillsScreen() async {
    final result = await _apiClient.get('/screens/bills');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> createRecurringBill(
    Map<String, dynamic> data,
  ) async {
    final result = await _apiClient.post('/bill-templates', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateRecurringBill(
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _apiClient.put('/bill-templates/$id', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<void> stopRecurringBill(
    String id, {
    bool cancelFutureUnpaid = true,
  }) async {
    final result = await _apiClient.post('/bill-templates/$id/stop', data: {
      'cancelFutureUnpaid': cancelFutureUnpaid,
    });
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  @override
  Future<void> deleteBill(String id) async {
    final result = await _apiClient.delete('/bills/$id');
    result.fold(
      (failure) => throw ServerException(message: failure.message),
      (_) => null,
    );
  }

  @override
  Future<Map<String, dynamic>> previewBillPayment(
    String id, {
    String? amount,
  }) async {
    final data = <String, dynamic>{};
    if (amount != null) data['amount'] = amount;
    final result = await _apiClient.post('/bills/$id/pay-preview', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> settleBill({
    required String id,
    required String walletId,
    required String occurredAt,
    String? amount,
    String? note,
    bool allowNegativeAvailable = false,
  }) async {
    final data = <String, dynamic>{
      'walletId': walletId,
      'occurredAt': occurredAt,
      'allowNegativeAvailable': allowNegativeAvailable,
    };
    if (amount != null) data['amount'] = amount;
    if (note != null && note.isNotEmpty) data['note'] = note;
    final result = await _apiClient.post('/bills/$id/settle', data: data);
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        return res['data'] as Map<String, dynamic>? ?? res;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> linkBill({
    required String billId,
    required String transactionId,
    required int expectedVersion,
  }) async {
    final result = await _apiClient.post('/bills/$billId/link', data: {
      'transactionId': transactionId,
      'expectedVersion': expectedVersion,
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
  Future<List<Map<String, dynamic>>> getBillCandidateTransactions(
    String billId, {
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) params['search'] = search;
    final result = await _apiClient.get(
      '/bills/$billId/candidate-transactions',
      queryParameters: params,
    );
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (body) {
        final res = body as Map<String, dynamic>;
        final d = res['data'];
        if (d is List) return d.cast<Map<String, dynamic>>();
        return [];
      },
    );
  }
}

final budgetRemoteDataSourceProvider =
    Provider<BudgetRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BudgetRemoteDataSourceImpl(apiClient);
});
