import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardData> getDashboard();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<DashboardData> getDashboard() async {
    final result = await _apiClient.get('/dashboard');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        // Backend: { data: { overview, recentEntries, upcomingBills, ... } }
        final d = body['data'] as Map<String, dynamic>? ?? body;
        return _parseDashboard(d);
      },
    );
  }

  DashboardData _parseDashboard(Map<String, dynamic> d) {
    // Overview: tổng số dư các ví
    final overview = d['overview'] as Map<String, dynamic>? ?? {};
    final wallets = overview['wallets'] as List<dynamic>? ?? [];
    double totalBalance = 0;
    double totalIncome = 0;
    double totalExpense = 0;

    for (final w in wallets) {
      final bal = _toDouble(w['balance']);
      if (bal >= 0) totalBalance += bal;
    }

    // Period summary (thu/chi tháng này)
    final period = d['period'] as Map<String, dynamic>? ?? {};
    totalIncome = _toDouble(period['totalIncome'] ?? period['income']);
    totalExpense = _toDouble(period['totalExpense'] ?? period['expense']);
    if (totalBalance == 0) {
      totalBalance = totalIncome - totalExpense;
    }

    // Recent transactions
    final rawEntries = d['recentEntries'] as List<dynamic>? ?? [];
    final recentTransactions = rawEntries
        .take(10)
        .map((e) => _parseTransaction(e as Map<String, dynamic>))
        .toList();

    // Weekly data (fallback: tạo 7 cột trống)
    final weeklyData = <WeeklySpending>[
      const WeeklySpending(dayLabel: 'T2', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T3', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T4', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T5', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T6', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T7', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'CN', income: 0, expense: 0),
    ];

    return DashboardData(
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      recentTransactions: recentTransactions,
      weeklyData: weeklyData,
    );
  }

  Transaction _parseTransaction(Map<String, dynamic> e) {
    final amount = _toDouble(e['amount'] ?? e['netAmount']);
    final catName = _categoryName(e);
    return Transaction(
      id: e['_id']?.toString() ?? '',
      title: e['memo']?.toString() ??
          e['description']?.toString() ??
          catName,
      category: catName,
      amount: amount,
      date: _parseDate(e['occurredAt'] ?? e['createdAt']),
      note: e['note']?.toString(),
      icon: _iconFor(catName, amount),
    );
  }

  String _categoryName(Map<String, dynamic> e) {
    final cat = e['category'];
    if (cat is Map) return cat['name']?.toString() ?? 'Khác';
    if (cat is String) return cat;
    final impacts = e['impacts'] as List<dynamic>?;
    if (impacts != null && impacts.isNotEmpty) {
      final first = impacts.first as Map<String, dynamic>? ?? {};
      final wallet = first['wallet'];
      if (wallet is Map) return wallet['name']?.toString() ?? 'Khác';
    }
    return 'Khác';
  }

  TransactionIcon _iconFor(String category, double amount) {
    final cat = category.toLowerCase();
    if (cat.contains('ăn') || cat.contains('food') || cat.contains('cà phê') || cat.contains('quán')) {
      return TransactionIcon.food;
    }
    if (cat.contains('xe') || cat.contains('grab') || cat.contains('di chuyển') || cat.contains('xăng')) {
      return TransactionIcon.transport;
    }
    if (cat.contains('mua') || cat.contains('shop') || cat.contains('shopee')) {
      return TransactionIcon.shopping;
    }
    if (cat.contains('y tế') || cat.contains('sức khoẻ') || cat.contains('bệnh')) {
      return TransactionIcon.health;
    }
    if (cat.contains('lương') || cat.contains('salary') || amount > 0) {
      return TransactionIcon.salary;
    }
    if (cat.contains('chuyển') || cat.contains('transfer')) {
      return TransactionIcon.transfer;
    }
    return TransactionIcon.other;
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    try {
      return DateTime.parse(val.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    // Backend có thể trả về { '$numberLong': '...' }
    if (val is Map) {
      final raw = val['\$numberLong'] ?? val['low'];
      if (raw != null) return double.tryParse(raw.toString()) ?? 0.0;
    }
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRemoteDataSourceImpl(apiClient);
});
